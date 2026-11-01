-- Lite core schema: identity, policies, access, overrides and immutable audit.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='docuguard_runtime') THEN CREATE ROLE docuguard_runtime NOLOGIN; END IF; END $$;
CREATE TABLE departments (department_id SERIAL PRIMARY KEY, department_name VARCHAR(100) NOT NULL UNIQUE, description TEXT);
CREATE TABLE roles (role_id SERIAL PRIMARY KEY, role_name VARCHAR(50) NOT NULL UNIQUE CHECK (role_name IN ('Admin','Doctor','Nurse','Staff')), description TEXT);
CREATE TABLE users (
 user_id SERIAL PRIMARY KEY, full_name VARCHAR(150) NOT NULL,
 email VARCHAR(255) NOT NULL UNIQUE CHECK (email LIKE '%@%'), password_hash VARCHAR(255) NOT NULL,
 role_id INT NOT NULL REFERENCES roles(role_id) ON DELETE RESTRICT,
 department_id INT REFERENCES departments(department_id) ON DELETE SET NULL,
 employment_status VARCHAR(20) DEFAULT 'active',
 account_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (account_status IN ('active','suspended','disabled')),
 created_at TIMESTAMP NOT NULL DEFAULT now(), last_login_at TIMESTAMP
);
CREATE TABLE document_categories (category_id SERIAL PRIMARY KEY, category_name VARCHAR(100) NOT NULL UNIQUE, description TEXT);
-- current_version_id is added after document_versions exists (02_alter.sql).
CREATE TABLE documents (
 document_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL,
 category_id INT NOT NULL REFERENCES document_categories(category_id) ON DELETE RESTRICT,
 owner_id INT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT, current_version_id INT,
 mongo_doc_id VARCHAR(64) NOT NULL UNIQUE,
 document_status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (document_status IN ('draft','active','under_review','retired')),
 created_at TIMESTAMP NOT NULL DEFAULT now(), updated_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE TABLE document_versions (
 version_id SERIAL PRIMARY KEY, document_id INT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
 version_number INT NOT NULL CHECK (version_number > 0), file_path VARCHAR(500) NOT NULL,
 mongo_content_id VARCHAR(64) NOT NULL UNIQUE, checksum VARCHAR(128) NOT NULL,
 uploaded_by INT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
 approved_by INT REFERENCES users(user_id) ON DELETE RESTRICT,
 uploaded_at TIMESTAMP NOT NULL DEFAULT now(), approved_at TIMESTAMP,
 effective_date DATE NOT NULL, expiry_date DATE CHECK (expiry_date > effective_date),
 version_status VARCHAR(20) NOT NULL DEFAULT 'pending_review' CHECK (version_status IN ('pending_review','approved','superseded','expired')),
 UNIQUE (document_id,version_number), CHECK (approved_by <> uploaded_by),
 CHECK ((approved_by IS NULL) = (approved_at IS NULL))
);
CREATE TABLE document_permissions (
 doc_permission_id SERIAL PRIMARY KEY, document_id INT NOT NULL REFERENCES documents(document_id) ON DELETE CASCADE,
 role_id INT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
 access_level VARCHAR(20) NOT NULL CHECK (access_level IN ('read','write','approve','admin')),
 granted_by INT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
 granted_at TIMESTAMP NOT NULL DEFAULT now(), revoked_at TIMESTAMP,
 UNIQUE (document_id,role_id,access_level)
);
CREATE TABLE access_overrides (
 override_id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
 document_id INT NOT NULL REFERENCES documents(document_id) ON DELETE RESTRICT,
 justification TEXT NOT NULL CHECK (char_length(trim(justification)) >= 20),
 granted_at TIMESTAMP NOT NULL DEFAULT now(), expires_at TIMESTAMP NOT NULL,
 status VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','reviewed')),
 reviewed_by INT REFERENCES users(user_id) ON DELETE RESTRICT, reviewed_at TIMESTAMP,
 review_outcome VARCHAR(15) CHECK (review_outcome IN ('justified','unjustified')),
 CHECK (expires_at > granted_at), CHECK (expires_at <= granted_at + interval '24 hours'), CHECK (reviewed_by <> user_id)
);
CREATE TABLE access_logs (
 log_id BIGSERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
 document_id INT NOT NULL REFERENCES documents(document_id) ON DELETE RESTRICT,
 version_id INT REFERENCES document_versions(version_id) ON DELETE RESTRICT,
 override_id INT REFERENCES access_overrides(override_id) ON DELETE RESTRICT,
 action VARCHAR(20) NOT NULL CHECK (action IN ('view','download','upload','edit','approve')),
 is_break_glass BOOLEAN NOT NULL DEFAULT false, ip_address VARCHAR(45), accessed_at TIMESTAMP NOT NULL DEFAULT now(),
 prev_hash CHAR(64) NOT NULL, row_hash CHAR(64) NOT NULL UNIQUE,
 CHECK (is_break_glass = (override_id IS NOT NULL))
);
GRANT USAGE ON SCHEMA public TO docuguard_runtime;
GRANT SELECT,INSERT,UPDATE,DELETE ON departments,roles,users,document_categories,documents,document_versions,document_permissions,access_overrides TO docuguard_runtime;
GRANT SELECT,INSERT ON access_logs TO docuguard_runtime;
REVOKE UPDATE,DELETE ON access_logs FROM docuguard_runtime;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO docuguard_runtime;
