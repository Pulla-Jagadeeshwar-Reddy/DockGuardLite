CREATE OR REPLACE FUNCTION fn_validate_version_transition() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.version_status IS DISTINCT FROM OLD.version_status THEN
  IF NOT ((OLD.version_status='pending_review' AND NEW.version_status IN ('approved','expired'))
   OR (OLD.version_status='approved' AND NEW.version_status IN ('superseded','expired'))) THEN
   RAISE EXCEPTION 'invalid document version transition: % -> %',OLD.version_status,NEW.version_status USING ERRCODE='23514';
  END IF;
  IF NEW.version_status='approved' THEN NEW.approved_at:=COALESCE(NEW.approved_at,now()); END IF;
 END IF; RETURN NEW;
END; $$;
CREATE OR REPLACE FUNCTION fn_after_version_approved() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE previous_id INT;
BEGIN
 -- Pointer switch and superseding stay in the approval transaction.
 SELECT current_version_id INTO previous_id FROM documents WHERE document_id=NEW.document_id FOR UPDATE;
 IF previous_id IS NOT NULL AND previous_id<>NEW.version_id THEN
  UPDATE document_versions SET version_status='superseded' WHERE version_id=previous_id AND version_status='approved';
 END IF;
 UPDATE documents SET current_version_id=NEW.version_id,document_status='active' WHERE document_id=NEW.document_id;
 RETURN NEW;
END; $$;
CREATE TRIGGER trg_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_version_transition BEFORE UPDATE ON document_versions FOR EACH ROW EXECUTE FUNCTION fn_validate_version_transition();
CREATE TRIGGER trg_version_approved AFTER UPDATE OF version_status ON document_versions FOR EACH ROW
 WHEN (OLD.version_status IS DISTINCT FROM NEW.version_status AND NEW.version_status='approved') EXECUTE FUNCTION fn_after_version_approved();
CREATE TRIGGER trg_audit_chain BEFORE INSERT ON access_logs FOR EACH ROW EXECUTE FUNCTION fn_audit_chain_before_insert();
CREATE TRIGGER trg_audit_immutable BEFORE UPDATE OR DELETE ON access_logs FOR EACH ROW EXECUTE FUNCTION fn_audit_chain_immutable();
REVOKE UPDATE,DELETE ON TABLE access_logs FROM docuguard_runtime;
