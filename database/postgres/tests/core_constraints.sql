\set ON_ERROR_STOP on
BEGIN;
SELECT user_id AS admin_id FROM users WHERE email='admin1@docuguard.local'\gset
SELECT user_id AS reviewer_id FROM users WHERE email='admin2@docuguard.local'\gset
SELECT user_id AS nurse_id FROM users WHERE email='nurse1@docuguard.local'\gset
SELECT user_id AS doctor_id FROM users WHERE email='doctor1@docuguard.local'\gset
SELECT role_id AS nurse_role_id FROM roles WHERE role_name='Nurse'\gset
SELECT category_id AS category_id FROM document_categories WHERE category_name='Patient Safety'\gset
INSERT INTO documents(title,category_id,owner_id,mongo_doc_id)
VALUES('Lite SQL constraint fixture',:category_id,:admin_id,'sql-core-'||txid_current())
RETURNING document_id AS document_id\gset
SELECT set_config('docuguard.test_document_id', :'document_id', true);

DO $$
DECLARE
 admin_id INT; reviewer_id INT; nurse_id INT; doctor_id INT; nurse_role_id INT; doc_id INT;
 fixture_version_id INT; fixture_override_id INT; fixture_log_id BIGINT; rejected BOOLEAN;
BEGIN
 SELECT user_id INTO admin_id FROM users WHERE email='admin1@docuguard.local';
 SELECT user_id INTO reviewer_id FROM users WHERE email='admin2@docuguard.local';
 SELECT user_id INTO nurse_id FROM users WHERE email='nurse1@docuguard.local';
 SELECT user_id INTO doctor_id FROM users WHERE email='doctor1@docuguard.local';
 SELECT role_id INTO nurse_role_id FROM roles WHERE role_name='Nurse';
 doc_id:=current_setting('docuguard.test_document_id')::INT;
 IF NOT EXISTS(SELECT 1 FROM users WHERE email='admin1@docuguard.local' AND left(password_hash,7)='$2a$12$' AND crypt('DG-Demo-Admin-01!',password_hash)=password_hash) THEN
  RAISE EXCEPTION 'demo password must be a cost-12 bcrypt hash';
 END IF;

 rejected:=false;
 BEGIN UPDATE users SET account_status='unknown' WHERE user_id=nurse_id;
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'invalid account_status was accepted'; END IF;

 rejected:=false;
 BEGIN
  INSERT INTO document_versions(document_id,version_number,file_path,mongo_content_id,checksum,uploaded_by,approved_by,approved_at,effective_date,version_status)
  VALUES(doc_id,1,'same-user.pdf','bad-maker-checker-'||txid_current(),repeat('a',64),admin_id,admin_id,now(),CURRENT_DATE,'approved');
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'maker-checker allowed the uploader to approve their own version'; END IF;

 INSERT INTO document_versions(document_id,version_number,file_path,mongo_content_id,checksum,uploaded_by,effective_date,version_status)
 VALUES(doc_id,1,'fixture.pdf','sql-core-content-'||txid_current(),md5('core-check-'||txid_current()::text),doctor_id,CURRENT_DATE,'pending_review') RETURNING document_versions.version_id INTO fixture_version_id;
 UPDATE document_versions SET approved_by=reviewer_id,approved_at=now(),version_status='approved' WHERE document_versions.version_id=fixture_version_id;
 IF (SELECT current_version_id FROM documents WHERE document_id=doc_id)<>fixture_version_id THEN RAISE EXCEPTION 'approval trigger did not set current_version_id'; END IF;
 IF (SELECT document_status FROM documents WHERE document_id=doc_id)<>'active' THEN RAISE EXCEPTION 'approval trigger did not activate document'; END IF;

 rejected:=false;
 BEGIN INSERT INTO document_permissions(document_id,role_id,access_level,granted_by) VALUES(doc_id,nurse_role_id,'owner',admin_id);
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'invalid document access_level was accepted'; END IF;
 INSERT INTO document_permissions(document_id,role_id,access_level,granted_by) VALUES(doc_id,nurse_role_id,'read',admin_id);
 rejected:=false;
 BEGIN INSERT INTO document_permissions(document_id,role_id,access_level,granted_by) VALUES(doc_id,nurse_role_id,'read',admin_id);
 EXCEPTION WHEN unique_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'duplicate document grant was accepted'; END IF;
 IF NOT EXISTS(SELECT 1 FROM fn_accessible_document_ids(nurse_id) WHERE document_id=doc_id) THEN RAISE EXCEPTION 'role grant did not allow document access'; END IF;
 IF EXISTS(SELECT 1 FROM fn_accessible_document_ids((SELECT user_id FROM users WHERE email='staff1@docuguard.local')) WHERE document_id=doc_id) THEN RAISE EXCEPTION 'ungranted role received document access'; END IF;

 rejected:=false;
 BEGIN INSERT INTO access_overrides(user_id,document_id,justification,expires_at) VALUES(nurse_id,doc_id,'Too short',now()+interval '1 hour');
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'short emergency justification was accepted'; END IF;
 rejected:=false;
 BEGIN INSERT INTO access_overrides(user_id,document_id,justification,expires_at) VALUES(nurse_id,doc_id,'A sufficiently long test justification',now()+interval '25 hours');
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'emergency grant over 24 hours was accepted'; END IF;
 rejected:=false;
 BEGIN INSERT INTO access_overrides(user_id,document_id,justification,expires_at,reviewed_by,reviewed_at,review_outcome)
 VALUES(nurse_id,doc_id,'A sufficiently long test justification',now()+interval '1 hour',nurse_id,now(),'justified');
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'requester was allowed to review own emergency access'; END IF;
 INSERT INTO access_overrides(user_id,document_id,justification,granted_at,expires_at)
 VALUES(nurse_id,doc_id,'A sufficiently long test justification',now()-interval '2 hours',now()-interval '1 hour') RETURNING access_overrides.override_id INTO fixture_override_id;
 PERFORM fn_expire_overrides();
 IF (SELECT status FROM access_overrides WHERE access_overrides.override_id=fixture_override_id)<>'expired' THEN RAISE EXCEPTION 'override sweeper did not expire elapsed access'; END IF;

 rejected:=false;
 BEGIN INSERT INTO policy_assignments(document_id,assigned_by,due_date) VALUES(doc_id,admin_id,CURRENT_DATE+1);
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'assignment without target was accepted'; END IF;
 rejected:=false;
 BEGIN INSERT INTO access_logs(user_id,document_id,action,is_break_glass) VALUES(admin_id,doc_id,'view',true);
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'break-glass audit flag without override was accepted'; END IF;

 INSERT INTO access_logs(user_id,document_id,version_id,action,ip_address) VALUES(admin_id,doc_id,fixture_version_id,'view','203.0.113.10') RETURNING access_logs.log_id INTO fixture_log_id;
 IF verify_audit_chain() IS NOT NULL THEN RAISE EXCEPTION 'new audit row did not produce a valid hash chain'; END IF;
 rejected:=false;
 BEGIN UPDATE access_logs SET action='download' WHERE access_logs.log_id=fixture_log_id;
 EXCEPTION WHEN SQLSTATE '55000' THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'audit UPDATE was not rejected'; END IF;
 rejected:=false;
 BEGIN DELETE FROM access_logs WHERE access_logs.log_id=fixture_log_id;
 EXCEPTION WHEN SQLSTATE '55000' THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'audit DELETE was not rejected'; END IF;
 ALTER TABLE access_logs DISABLE TRIGGER trg_audit_immutable;
 UPDATE access_logs SET ip_address='203.0.113.11' WHERE access_logs.log_id=fixture_log_id;
 ALTER TABLE access_logs ENABLE TRIGGER trg_audit_immutable;
 IF verify_audit_chain() IS DISTINCT FROM fixture_log_id THEN RAISE EXCEPTION 'verifier failed to identify the tampered audit row'; END IF;
 IF has_table_privilege('docuguard_runtime','public.access_logs','UPDATE') OR has_table_privilege('docuguard_runtime','public.access_logs','DELETE') THEN
  RAISE EXCEPTION 'runtime role can mutate access logs';
 END IF;
END $$;
ROLLBACK;
\echo Lite core constraint, maker-checker, access, override, and audit tests passed.
