-- Fictional policy metadata and version rows; Mongo content is seeded separately.
INSERT INTO documents(title,category_id,owner_id,mongo_doc_id,document_status)
SELECT s.title,c.category_id,u.user_id,s.mongo_doc_id,'draft'
FROM (VALUES
 ('Standard Precautions and Sharps Injury Response','Infection Control','doctor1@docuguard.local','demo-infection-control'),
 ('Patient Information Privacy and Minimum Necessary Access','Privacy','doctor1@docuguard.local','demo-patient-privacy'),
 ('Emergency Department Patient Identification','Patient Safety','doctor2@docuguard.local','demo-patient-identification'),
 ('Hand Hygiene for Clinical Staff','Infection Control','doctor1@docuguard.local','demo-hand-hygiene'),
 ('Hand Hygiene Quick Reference','Infection Control','doctor2@docuguard.local','demo-hand-hygiene-quick'),
 ('Medication Safety and Independent Checks','Medication Safety','doctor2@docuguard.local','demo-medication-safety'),
 ('Biomedical Waste Segregation','Waste Management','nurse1@docuguard.local','demo-biomedical-waste'),
 ('Emergency Code and Incident Communication','Emergency Preparedness','doctor1@docuguard.local','demo-emergency-code'),
 ('Visitor Access and Conduct','Administration','staff1@docuguard.local','demo-visitor-access'),
 ('Records Retention Schedule Seven Year Example','Records Management','admin1@docuguard.local','demo-retention-seven-year'),
 ('Records Retention Schedule Ten Year Example','Records Management','admin1@docuguard.local','demo-retention-ten-year'),
 ('Backup and Disaster Recovery','Emergency Preparedness','admin1@docuguard.local','demo-backup-recovery')
) s(title,category_name,owner_email,mongo_doc_id)
JOIN document_categories c ON c.category_name=s.category_name JOIN users u ON u.email=s.owner_email
WHERE NOT EXISTS(SELECT 1 FROM documents d WHERE d.mongo_doc_id=s.mongo_doc_id);
INSERT INTO document_versions(document_id,version_number,file_path,mongo_content_id,checksum,uploaded_by,effective_date,expiry_date,version_status)
SELECT d.document_id,1,s.file_path,s.mongo_content_id,s.checksum,u.user_id,CURRENT_DATE+s.effective_offset,
 CASE WHEN s.expiry_offset IS NULL THEN NULL ELSE CURRENT_DATE+s.expiry_offset END,'pending_review'
FROM (VALUES
 ('demo-infection-control','standard-precautions-and-sharps-injury-response.pdf','demo-content-infection-control-v1',repeat('1',64),'doctor1@docuguard.local',-30,335),
 ('demo-patient-privacy','patient-information-privacy-and-minimum-necessary-access.pdf','demo-content-patient-privacy-v1',repeat('2',64),'doctor1@docuguard.local',-30,335),
 ('demo-patient-identification','emergency-department-patient-identification.pdf','demo-content-patient-identification-v1',repeat('3',64),'doctor2@docuguard.local',-30,335),
 ('demo-hand-hygiene','hand-hygiene-for-clinical-staff.pdf','demo-content-hand-hygiene-v1',repeat('4',64),'doctor1@docuguard.local',-30,335),
 ('demo-hand-hygiene-quick','hand-hygiene-quick-reference.pdf','demo-content-hand-hygiene-quick-v1',repeat('5',64),'doctor2@docuguard.local',-30,335),
 ('demo-medication-safety','medication-safety-and-independent-checks.pdf','demo-content-medication-safety-v1',repeat('7',64),'doctor2@docuguard.local',-30,335),
 ('demo-biomedical-waste','biomedical-waste-segregation.pdf','demo-content-biomedical-waste-v1',repeat('8',64),'nurse1@docuguard.local',-30,335),
 ('demo-emergency-code','emergency-code-and-incident-communication.pdf','demo-content-emergency-code-v1',repeat('9',64),'doctor1@docuguard.local',-30,335),
 ('demo-visitor-access','visitor-access-and-conduct.pdf','demo-content-visitor-access-v1',repeat('a',64),'staff1@docuguard.local',-30,335),
 ('demo-retention-seven-year','records-retention-schedule-seven-year-example.pdf','demo-content-retention-seven-year-v1',repeat('b',64),'admin1@docuguard.local',-3650,-1),
 ('demo-retention-ten-year','records-retention-schedule-ten-year-example.pdf','demo-content-retention-ten-year-v1',repeat('c',64),'admin1@docuguard.local',-30,20),
 ('demo-backup-recovery','backup-and-disaster-recovery.pdf','demo-content-backup-recovery-v1',repeat('d',64),'admin1@docuguard.local',-30,335)
) s(mongo_doc_id,file_path,mongo_content_id,checksum,uploader_email,effective_offset,expiry_offset)
JOIN documents d ON d.mongo_doc_id=s.mongo_doc_id JOIN users u ON u.email=s.uploader_email
WHERE NOT EXISTS(SELECT 1 FROM document_versions v WHERE v.document_id=d.document_id AND v.version_number=1);
-- A second Admin approves each synthetic version (maker-checker).
UPDATE document_versions v SET approved_by=a.user_id,approved_at=now(),version_status='approved'
FROM documents d,users a WHERE v.document_id=d.document_id AND a.email='admin2@docuguard.local'
 AND v.version_number=1 AND v.version_status='pending_review' AND d.mongo_doc_id LIKE 'demo-%';
SELECT fn_expiry_sweep();
