CREATE OR REPLACE FUNCTION fn_set_updated_at() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at:=now(); RETURN NEW; END; $$;
CREATE OR REPLACE FUNCTION fn_accessible_document_ids(p_user_id INT)
RETURNS TABLE(document_id INT) LANGUAGE sql STABLE SECURITY INVOKER SET search_path=pg_catalog,public AS $$
 SELECT dp.document_id FROM public.document_permissions dp JOIN public.users u ON u.role_id=dp.role_id
 WHERE u.user_id=p_user_id AND u.account_status='active' AND dp.revoked_at IS NULL
 UNION SELECT ao.document_id FROM public.access_overrides ao JOIN public.users u ON u.user_id=ao.user_id
 WHERE ao.user_id=p_user_id AND u.account_status='active' AND ao.status='active' AND ao.expires_at>now();
$$;
CREATE OR REPLACE FUNCTION fn_access_log_hash(p_prev_hash CHAR(64),p_log_id BIGINT,p_user_id INT,p_document_id INT,
 p_version_id INT,p_override_id INT,p_action VARCHAR(20),p_is_break_glass BOOLEAN,p_ip_address VARCHAR(45),p_accessed_at TIMESTAMP)
RETURNS CHAR(64) LANGUAGE sql IMMUTABLE AS $$
 SELECT encode(digest(concat_ws('|',p_prev_hash::text,p_log_id::text,p_user_id::text,p_document_id::text,
 p_version_id::text,p_override_id::text,p_action,p_is_break_glass::text,p_ip_address,
 extract(epoch FROM p_accessed_at)::text),'sha256'),'hex')::CHAR(64);
$$;
CREATE OR REPLACE FUNCTION fn_audit_chain_before_insert() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE last_hash CHAR(64); last_id BIGINT; candidate_id BIGINT;
BEGIN
 -- Serialize appenders so concurrent transactions cannot use the same predecessor.
 PERFORM pg_advisory_xact_lock(727001);
 SELECT log_id,row_hash INTO last_id,last_hash FROM access_logs ORDER BY log_id DESC LIMIT 1;
 candidate_id:=nextval(pg_get_serial_sequence('public.access_logs','log_id'));
 WHILE last_id IS NOT NULL AND candidate_id<=last_id LOOP candidate_id:=nextval(pg_get_serial_sequence('public.access_logs','log_id')); END LOOP;
 NEW.log_id:=candidate_id; NEW.prev_hash:=COALESCE(last_hash,repeat('0',64)::CHAR(64));
 NEW.row_hash:=fn_access_log_hash(NEW.prev_hash,NEW.log_id,NEW.user_id,NEW.document_id,NEW.version_id,
 NEW.override_id,NEW.action,NEW.is_break_glass,NEW.ip_address,NEW.accessed_at);
 RETURN NEW;
END; $$;
CREATE OR REPLACE FUNCTION fn_audit_chain_immutable() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'access_logs are insert-only; UPDATE and DELETE are prohibited' USING ERRCODE='55000'; END; $$;
CREATE OR REPLACE FUNCTION verify_audit_chain() RETURNS BIGINT LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path=pg_catalog,public AS $$
DECLARE item RECORD; expected_prev CHAR(64):=repeat('0',64)::CHAR(64); expected_hash CHAR(64);
BEGIN
 FOR item IN SELECT log_id,user_id,document_id,version_id,override_id,action,is_break_glass,ip_address,
   accessed_at,prev_hash,row_hash FROM public.access_logs ORDER BY log_id LOOP
   IF item.prev_hash IS DISTINCT FROM expected_prev THEN RETURN item.log_id; END IF;
   expected_hash:=public.fn_access_log_hash(item.prev_hash,item.log_id,item.user_id,item.document_id,
     item.version_id,item.override_id,item.action,item.is_break_glass,item.ip_address,item.accessed_at);
   IF item.row_hash IS DISTINCT FROM expected_hash THEN RETURN item.log_id; END IF;
   expected_prev:=item.row_hash;
 END LOOP; RETURN NULL;
END; $$;
CREATE OR REPLACE FUNCTION fn_expire_overrides() RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE changed_rows INTEGER;
BEGIN UPDATE access_overrides SET status='expired' WHERE status='active' AND expires_at<=now();
 GET DIAGNOSTICS changed_rows=ROW_COUNT; RETURN changed_rows; END; $$;
-- Expiry changes version state only; the UI reads current rows directly.
CREATE OR REPLACE FUNCTION fn_expiry_sweep() RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE changed_rows INTEGER;
BEGIN UPDATE document_versions SET version_status='expired' WHERE version_status='approved' AND expiry_date<CURRENT_DATE;
 GET DIAGNOSTICS changed_rows=ROW_COUNT; RETURN changed_rows; END; $$;
GRANT EXECUTE ON FUNCTION fn_accessible_document_ids(INT),verify_audit_chain(),fn_expire_overrides(),fn_expiry_sweep() TO docuguard_runtime;
