-- Role-specific grants. Backup recovery remains Admin-only for the access demo.
INSERT INTO document_permissions(document_id,role_id,access_level,granted_by)
SELECT d.document_id,r.role_id,'read',g.user_id FROM documents d
JOIN users g ON g.email='admin1@docuguard.local' JOIN roles r ON r.role_name='Admin'
WHERE d.mongo_doc_id LIKE 'demo-%' ON CONFLICT DO NOTHING;
INSERT INTO document_permissions(document_id,role_id,access_level,granted_by)
SELECT d.document_id,r.role_id,'read',g.user_id FROM documents d
JOIN users g ON g.email='admin1@docuguard.local' JOIN roles r ON r.role_name='Doctor'
WHERE d.mongo_doc_id IN ('demo-infection-control','demo-patient-identification','demo-hand-hygiene','demo-hand-hygiene-quick',
 'demo-medication-safety','demo-biomedical-waste','demo-emergency-code') ON CONFLICT DO NOTHING;
INSERT INTO document_permissions(document_id,role_id,access_level,granted_by)
SELECT d.document_id,r.role_id,'read',g.user_id FROM documents d
JOIN users g ON g.email='admin1@docuguard.local' JOIN roles r ON r.role_name='Nurse'
WHERE d.mongo_doc_id IN ('demo-infection-control','demo-patient-identification','demo-hand-hygiene','demo-hand-hygiene-quick',
 'demo-medication-safety','demo-biomedical-waste','demo-emergency-code','demo-visitor-access') ON CONFLICT DO NOTHING;
INSERT INTO document_permissions(document_id,role_id,access_level,granted_by)
SELECT d.document_id,r.role_id,'read',g.user_id FROM documents d
JOIN users g ON g.email='admin1@docuguard.local' JOIN roles r ON r.role_name='Staff'
WHERE d.mongo_doc_id IN ('demo-patient-privacy','demo-biomedical-waste','demo-visitor-access','demo-retention-seven-year','demo-retention-ten-year')
ON CONFLICT DO NOTHING;
-- One assignment for each role makes My Policies useful for all seeded personnel.
INSERT INTO policy_assignments(document_id,target_role_id,assigned_by,due_date)
SELECT d.document_id,r.role_id,a.user_id,CURRENT_DATE+14 FROM documents d JOIN roles r ON r.role_name='Nurse'
JOIN users a ON a.email='admin1@docuguard.local' WHERE d.mongo_doc_id='demo-infection-control'
AND NOT EXISTS(SELECT 1 FROM policy_assignments x WHERE x.document_id=d.document_id AND x.target_role_id=r.role_id AND x.target_department_id IS NULL);
INSERT INTO policy_assignments(document_id,target_role_id,assigned_by,due_date)
SELECT d.document_id,r.role_id,a.user_id,CURRENT_DATE+14 FROM documents d JOIN roles r ON r.role_name='Doctor'
JOIN users a ON a.email='admin1@docuguard.local' WHERE d.mongo_doc_id='demo-patient-identification'
AND NOT EXISTS(SELECT 1 FROM policy_assignments x WHERE x.document_id=d.document_id AND x.target_role_id=r.role_id AND x.target_department_id IS NULL);
INSERT INTO policy_assignments(document_id,target_role_id,assigned_by,due_date)
SELECT d.document_id,r.role_id,a.user_id,CURRENT_DATE+14 FROM documents d JOIN roles r ON r.role_name='Staff'
JOIN users a ON a.email='admin1@docuguard.local' WHERE d.mongo_doc_id='demo-visitor-access'
AND NOT EXISTS(SELECT 1 FROM policy_assignments x WHERE x.document_id=d.document_id AND x.target_role_id=r.role_id AND x.target_department_id IS NULL);
INSERT INTO policy_assignments(document_id,target_role_id,assigned_by,due_date)
SELECT d.document_id,r.role_id,a.user_id,CURRENT_DATE+14 FROM documents d JOIN roles r ON r.role_name='Admin'
JOIN users a ON a.email='admin1@docuguard.local' WHERE d.mongo_doc_id='demo-backup-recovery'
AND NOT EXISTS(SELECT 1 FROM policy_assignments x WHERE x.document_id=d.document_id AND x.target_role_id=r.role_id AND x.target_department_id IS NULL);
-- Only completed acknowledgments are rows; pending remains an anti-join result.
INSERT INTO acknowledgments(assignment_id,user_id,version_id)
SELECT pa.assignment_id,u.user_id,v.version_id FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id
JOIN document_versions v ON v.version_id=d.current_version_id JOIN users u ON u.email='nurse1@docuguard.local'
WHERE d.mongo_doc_id='demo-infection-control' AND v.version_status='approved' ON CONFLICT DO NOTHING;
INSERT INTO acknowledgments(assignment_id,user_id,version_id)
SELECT pa.assignment_id,u.user_id,v.version_id FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id
JOIN document_versions v ON v.version_id=d.current_version_id JOIN users u ON u.email='doctor1@docuguard.local'
WHERE d.mongo_doc_id='demo-patient-identification' AND v.version_status='approved' ON CONFLICT DO NOTHING;
INSERT INTO acknowledgments(assignment_id,user_id,version_id)
SELECT pa.assignment_id,u.user_id,v.version_id FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id
JOIN document_versions v ON v.version_id=d.current_version_id JOIN users u ON u.email='staff1@docuguard.local'
WHERE d.mongo_doc_id='demo-visitor-access' AND v.version_status='approved' ON CONFLICT DO NOTHING;
