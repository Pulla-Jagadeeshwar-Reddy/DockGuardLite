-- Seed one pending and one reviewed emergency request for Admin review demos.
INSERT INTO access_overrides(user_id,document_id,justification,granted_at,expires_at,status)
SELECT u.user_id,d.document_id,'Urgent synthetic demonstration review of backup continuity policy.',now(),now()+interval '6 hours','active'
FROM users u CROSS JOIN documents d WHERE u.email='nurse1@docuguard.local' AND d.mongo_doc_id='demo-backup-recovery'
AND NOT EXISTS(SELECT 1 FROM access_overrides x WHERE x.user_id=u.user_id AND x.document_id=d.document_id AND x.reviewed_by IS NULL);
INSERT INTO access_logs(user_id,document_id,version_id,override_id,action,is_break_glass,ip_address)
SELECT ao.user_id,ao.document_id,d.current_version_id,ao.override_id,'view',true,'192.0.2.10'
FROM access_overrides ao JOIN documents d ON d.document_id=ao.document_id JOIN users u ON u.user_id=ao.user_id
WHERE u.email='nurse1@docuguard.local' AND d.mongo_doc_id='demo-backup-recovery'
AND NOT EXISTS(SELECT 1 FROM access_logs l WHERE l.override_id=ao.override_id);
INSERT INTO access_overrides(user_id,document_id,justification,granted_at,expires_at,status,reviewed_by,reviewed_at,review_outcome)
SELECT u.user_id,d.document_id,'Synthetic emergency access scenario reviewed for teaching.',now()-interval '1 day',now()-interval '18 hours',
 'reviewed',a.user_id,now()-interval '20 hours','justified'
FROM users u CROSS JOIN users a CROSS JOIN documents d WHERE u.email='doctor2@docuguard.local'
AND a.email='admin1@docuguard.local' AND d.mongo_doc_id='demo-retention-ten-year'
AND NOT EXISTS(SELECT 1 FROM access_overrides x WHERE x.user_id=u.user_id AND x.document_id=d.document_id AND x.reviewed_by=a.user_id);
INSERT INTO access_logs(user_id,document_id,version_id,override_id,action,is_break_glass,ip_address)
SELECT ao.user_id,ao.document_id,d.current_version_id,ao.override_id,'view',true,'192.0.2.11'
FROM access_overrides ao JOIN documents d ON d.document_id=ao.document_id JOIN users u ON u.user_id=ao.user_id
WHERE u.email='doctor2@docuguard.local' AND d.mongo_doc_id='demo-retention-ten-year'
AND NOT EXISTS(SELECT 1 FROM access_logs l WHERE l.override_id=ao.override_id);
-- Ordinary demo activity also enters through the hash-chain trigger.
INSERT INTO access_logs(user_id,document_id,version_id,action,ip_address)
SELECT u.user_id,d.document_id,d.current_version_id,'view','192.0.2.20'
FROM users u CROSS JOIN documents d WHERE u.email='nurse1@docuguard.local' AND d.mongo_doc_id='demo-infection-control'
AND NOT EXISTS(SELECT 1 FROM access_logs l WHERE l.user_id=u.user_id AND l.document_id=d.document_id AND l.action='view');
