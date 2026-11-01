\set ON_ERROR_STOP on
BEGIN;
DO $$
DECLARE
  doc_id INT; nurse_id INT; nurse_role_id INT; nurse_department_id INT; admin_id INT; reviewer_id INT; uploader_id INT;
  old_version_id INT; new_version_id INT; fixture_assignment_id INT; completed INT; pending INT; lineage_count INT; rejected BOOLEAN;
BEGIN
 SELECT d.document_id,d.current_version_id INTO doc_id,old_version_id FROM documents d WHERE d.mongo_doc_id='demo-infection-control';
 SELECT user_id,role_id,department_id INTO nurse_id,nurse_role_id,nurse_department_id FROM users WHERE email='nurse1@docuguard.local';
 SELECT user_id INTO admin_id FROM users WHERE email='admin1@docuguard.local';
 SELECT user_id INTO reviewer_id FROM users WHERE email='admin2@docuguard.local';
 SELECT user_id INTO uploader_id FROM users WHERE email='doctor1@docuguard.local';
 IF doc_id IS NULL OR old_version_id IS NULL THEN RAISE EXCEPTION 'expected Lite policy seed rows'; END IF;

 rejected:=false;
 BEGIN INSERT INTO policy_assignments(document_id,assigned_by,due_date) VALUES(doc_id,admin_id,CURRENT_DATE+10);
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'assignment without role or department target was accepted'; END IF;
 rejected:=false;
 BEGIN INSERT INTO policy_assignments(document_id,target_role_id,assigned_by,due_date)
 VALUES(doc_id,nurse_role_id,admin_id,CURRENT_DATE-1);
 EXCEPTION WHEN check_violation THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'past-due assignment was accepted'; END IF;

 INSERT INTO policy_assignments(document_id,target_role_id,target_department_id,assigned_by,due_date)
 VALUES(doc_id,nurse_role_id,nurse_department_id,admin_id,CURRENT_DATE+10) RETURNING policy_assignments.assignment_id INTO fixture_assignment_id;
 INSERT INTO acknowledgments(assignment_id,user_id,version_id) VALUES(fixture_assignment_id,nurse_id,old_version_id);
 SELECT acknowledged_users,pending_users INTO completed,pending FROM v_ack_compliance WHERE v_ack_compliance.assignment_id=fixture_assignment_id;
 IF completed<>1 OR pending<>0 THEN RAISE EXCEPTION 'acknowledgment completion view did not count current version'; END IF;

 INSERT INTO document_versions(document_id,version_number,file_path,mongo_content_id,checksum,uploaded_by,effective_date,expiry_date,version_status)
 SELECT doc_id,version_number+1,'sql-history-v2.pdf','sql-history-v2-'||txid_current(),md5('history-'||txid_current()::text),uploader_id,CURRENT_DATE,CURRENT_DATE+365,'pending_review'
 FROM document_versions WHERE version_id=old_version_id RETURNING version_id INTO new_version_id;
 UPDATE document_versions SET approved_by=reviewer_id,approved_at=now(),version_status='approved' WHERE version_id=new_version_id;
 IF (SELECT version_status FROM document_versions WHERE version_id=old_version_id)<>'superseded' THEN RAISE EXCEPTION 'approval did not supersede prior version'; END IF;
 SELECT acknowledged_users,pending_users INTO completed,pending FROM v_ack_compliance WHERE v_ack_compliance.assignment_id=fixture_assignment_id;
 IF completed<>0 OR pending<>1 THEN RAISE EXCEPTION 'new current version did not reopen acknowledgment'; END IF;

 WITH RECURSIVE history(document_id,version_number,depth,path) AS (
  SELECT document_id,version_number,1,ARRAY[version_number] FROM document_versions WHERE version_id=new_version_id
  UNION ALL
  SELECT prior.document_id,prior.version_number,current.depth+1,current.path||prior.version_number
  FROM history current JOIN document_versions prior ON prior.document_id=current.document_id
   AND prior.version_number=current.version_number-1
  WHERE NOT prior.version_number=ANY(current.path)
 ) SELECT count(*) INTO lineage_count FROM history;
 IF lineage_count<>2 THEN RAISE EXCEPTION 'recursive CTE expected two numbered versions, found %',lineage_count; END IF;
END $$;
ROLLBACK;
\echo Lite assignment, acknowledgment, version-history recursive CTE tests passed.
