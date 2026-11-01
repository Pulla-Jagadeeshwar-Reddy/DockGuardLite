-- Completion counts are derived from missing acknowledgments of the current version.
CREATE OR REPLACE VIEW v_ack_compliance AS
WITH eligible AS (
 SELECT pa.assignment_id,pa.document_id,d.title AS document_title,pa.target_role_id,
  tr.role_name AS target_role_name,pa.target_department_id,td.department_name AS target_department_name,
  pa.due_date,d.current_version_id AS version_id,u.user_id,u.full_name,u.department_id,u.role_id
 FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id
 JOIN document_versions v ON v.version_id=d.current_version_id
 JOIN users u ON u.account_status='active'
  AND (pa.target_role_id IS NULL OR pa.target_role_id=u.role_id)
  AND (pa.target_department_id IS NULL OR pa.target_department_id=u.department_id)
 LEFT JOIN roles tr ON tr.role_id=pa.target_role_id LEFT JOIN departments td ON td.department_id=pa.target_department_id
 WHERE d.document_status='active' AND v.version_status='approved'
  AND (v.expiry_date IS NULL OR v.expiry_date>=CURRENT_DATE)
), completion AS (
 SELECT e.*,(a.ack_id IS NOT NULL) AS acknowledged FROM eligible e
 LEFT JOIN acknowledgments a ON a.assignment_id=e.assignment_id AND a.user_id=e.user_id AND a.version_id=e.version_id
)
SELECT assignment_id,document_id,document_title,target_role_id,target_role_name,target_department_id,
 target_department_name,due_date,version_id,count(*)::INT AS eligible_users,
 count(*) FILTER(WHERE acknowledged)::INT AS acknowledged_users,
 count(*) FILTER(WHERE NOT acknowledged)::INT AS pending_users,
 CASE WHEN count(*)=0 THEN 0.00 ELSE round(100.0*count(*) FILTER(WHERE acknowledged)/count(*),2) END::NUMERIC(5,2) AS completion_percent
FROM completion GROUP BY assignment_id,document_id,document_title,target_role_id,target_role_name,
 target_department_id,target_department_name,due_date,version_id;
CREATE OR REPLACE VIEW v_ack_compliance_by_department AS
SELECT dep.department_id,dep.department_name,count(*)::INT AS eligible_assignments,
 count(*) FILTER(WHERE a.ack_id IS NOT NULL)::INT AS acknowledged_assignments,
 count(*) FILTER(WHERE a.ack_id IS NULL)::INT AS pending_assignments,
 CASE WHEN count(*)=0 THEN 0.00 ELSE round(100.0*count(*) FILTER(WHERE a.ack_id IS NOT NULL)/count(*),2) END::NUMERIC(5,2) AS completion_percent
FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id
 JOIN document_versions v ON v.version_id=d.current_version_id
 JOIN users u ON u.account_status='active'
  AND (pa.target_role_id IS NULL OR pa.target_role_id=u.role_id)
  AND (pa.target_department_id IS NULL OR pa.target_department_id=u.department_id)
 JOIN departments dep ON dep.department_id=u.department_id
 LEFT JOIN acknowledgments a ON a.assignment_id=pa.assignment_id AND a.user_id=u.user_id AND a.version_id=v.version_id
WHERE d.document_status='active' AND v.version_status='approved'
 AND (v.expiry_date IS NULL OR v.expiry_date>=CURRENT_DATE)
GROUP BY dep.department_id,dep.department_name;
GRANT SELECT ON v_ack_compliance,v_ack_compliance_by_department TO docuguard_runtime;
