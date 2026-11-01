-- Assignment and completed acknowledgment relations.
CREATE TABLE policy_assignments (
 assignment_id SERIAL PRIMARY KEY, document_id INT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
 target_role_id INT REFERENCES roles(role_id) ON DELETE CASCADE,
 target_department_id INT REFERENCES departments(department_id) ON DELETE CASCADE,
 assigned_by INT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
 assigned_at TIMESTAMP NOT NULL DEFAULT now(), due_date DATE NOT NULL,
 CHECK (target_role_id IS NOT NULL OR target_department_id IS NOT NULL),
 CHECK (due_date >= assigned_at::date)
);
CREATE TABLE acknowledgments (
 ack_id BIGSERIAL PRIMARY KEY, assignment_id INT NOT NULL REFERENCES policy_assignments(assignment_id) ON DELETE CASCADE,
 user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
 version_id INT NOT NULL REFERENCES document_versions(version_id) ON DELETE RESTRICT,
 acknowledged_at TIMESTAMP NOT NULL DEFAULT now(), UNIQUE (assignment_id,user_id,version_id)
);
GRANT SELECT,INSERT,UPDATE,DELETE ON policy_assignments,acknowledgments TO docuguard_runtime;
GRANT USAGE,SELECT ON SEQUENCE policy_assignments_assignment_id_seq,acknowledgments_ack_id_seq TO docuguard_runtime;
