CREATE INDEX idx_policy_assignments_document ON policy_assignments(document_id);
CREATE INDEX idx_policy_assignments_role_due ON policy_assignments(target_role_id,due_date);
CREATE INDEX idx_policy_assignments_department_due ON policy_assignments(target_department_id,due_date);
CREATE UNIQUE INDEX uq_policy_assignment_target ON policy_assignments(document_id,COALESCE(target_role_id,0),COALESCE(target_department_id,0));
CREATE INDEX idx_acknowledgments_user_version ON acknowledgments(user_id,version_id);
CREATE INDEX idx_acknowledgments_assignment ON acknowledgments(assignment_id);
