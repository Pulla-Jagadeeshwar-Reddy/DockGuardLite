-- Validate that each acknowledgment references the assignment's document and current approved version.
CREATE OR REPLACE FUNCTION fn_validate_acknowledgment() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE assigned_doc INT; assigned_version INT; actual_doc INT; actual_status VARCHAR(20);
BEGIN
 SELECT pa.document_id,d.current_version_id INTO assigned_doc,assigned_version
 FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id WHERE pa.assignment_id=NEW.assignment_id;
 SELECT document_id,version_status INTO actual_doc,actual_status FROM document_versions WHERE version_id=NEW.version_id;
 IF assigned_doc IS NULL OR actual_doc IS NULL OR assigned_doc<>actual_doc THEN
  RAISE EXCEPTION 'acknowledged version must belong to the assigned document' USING ERRCODE='23514';
 END IF;
 IF assigned_version IS DISTINCT FROM NEW.version_id OR actual_status<>'approved' THEN
  RAISE EXCEPTION 'only the current approved version can be acknowledged' USING ERRCODE='23514';
 END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER trg_validate_acknowledgment BEFORE INSERT ON acknowledgments
FOR EACH ROW EXECUTE FUNCTION fn_validate_acknowledgment();
