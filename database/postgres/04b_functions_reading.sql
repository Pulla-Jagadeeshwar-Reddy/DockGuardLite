-- Completion percentage is derived from assigned users and current-version acknowledgments.
CREATE OR REPLACE FUNCTION fn_assignment_completion(p_assignment_id INT)
RETURNS NUMERIC(5,2) LANGUAGE sql STABLE AS $$
 WITH eligible AS (
  SELECT u.user_id,d.current_version_id AS version_id
  FROM policy_assignments pa JOIN documents d ON d.document_id=pa.document_id
  JOIN users u ON u.account_status='active'
   AND (pa.target_role_id IS NULL OR pa.target_role_id=u.role_id)
   AND (pa.target_department_id IS NULL OR pa.target_department_id=u.department_id)
  JOIN document_versions v ON v.version_id=d.current_version_id AND v.version_status='approved'
  WHERE pa.assignment_id=p_assignment_id AND d.document_status='active'
   AND (v.expiry_date IS NULL OR v.expiry_date>=CURRENT_DATE)
 )
 SELECT COALESCE(round(100.0*count(a.ack_id)/NULLIF(count(e.user_id),0),2),0)::NUMERIC(5,2)
 FROM eligible e LEFT JOIN acknowledgments a ON a.assignment_id=p_assignment_id
  AND a.user_id=e.user_id AND a.version_id=e.version_id;
$$;
GRANT EXECUTE ON FUNCTION fn_assignment_completion(INT) TO docuguard_runtime;
