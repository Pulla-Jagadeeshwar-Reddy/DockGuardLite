-- Preserve demo personnel identities, role assignments, departments and bcrypt credentials.
INSERT INTO departments(department_name,description) VALUES
 ('Administration','Illustrative hospital administration department.'),('Emergency','Illustrative emergency and acute-care department.'),
 ('Nursing','Illustrative nursing department.'),('Surgery','Illustrative surgical services department.') ON CONFLICT(department_name) DO NOTHING;
INSERT INTO roles(role_name,description) VALUES
 ('Admin','Manages users, policies, audit review and configuration.'),
 ('Doctor','Reads permitted policies and may submit policy drafts.'),
 ('Nurse','Reads permitted policies and may request emergency access.'),
 ('Staff','Reads permitted non-clinical policies.') ON CONFLICT(role_name) DO NOTHING;
INSERT INTO document_categories(category_name,description) VALUES
 ('Infection Control','Infection-prevention policy category.'),('Patient Safety','Patient and workforce safety policy category.'),
 ('Privacy','Privacy and information-handling policy category.'),('Clinical Operations','Clinical workflow and procedure policy category.'),
 ('Administration','Administrative policy category.'),('Facilities Safety','Illustrative facilities and fire safety policies.'),
 ('Medication Safety','Illustrative medication handling policies.'),('Waste Management','Illustrative waste handling policies.'),
 ('Emergency Preparedness','Illustrative incident response and continuity policies.'),
 ('Records Management','Illustrative retention and information lifecycle policies.'),('Compliance','Compliance policy category.')
ON CONFLICT(category_name) DO NOTHING;
-- Demo passwords are fake teaching credentials; only salted bcrypt hashes persist.
INSERT INTO users(full_name,email,password_hash,role_id,department_id) VALUES
 ('Asha Admin','admin1@docuguard.local',crypt('DG-Demo-Admin-01!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Admin'),(SELECT department_id FROM departments WHERE department_name='Administration')),
 ('Rohan Admin','admin2@docuguard.local',crypt('DG-Demo-Admin-02!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Admin'),(SELECT department_id FROM departments WHERE department_name='Emergency')),
 ('Mira Doctor','doctor1@docuguard.local',crypt('DG-Demo-Doctor-01!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Doctor'),(SELECT department_id FROM departments WHERE department_name='Surgery')),
 ('Arjun Doctor','doctor2@docuguard.local',crypt('DG-Demo-Doctor-02!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Doctor'),(SELECT department_id FROM departments WHERE department_name='Emergency')),
 ('Nisha Nurse','nurse1@docuguard.local',crypt('DG-Demo-Nurse-01!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Nurse'),(SELECT department_id FROM departments WHERE department_name='Nursing')),
 ('Dev Nurse','nurse2@docuguard.local',crypt('DG-Demo-Nurse-02!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Nurse'),(SELECT department_id FROM departments WHERE department_name='Emergency')),
 ('Ira Staff','staff1@docuguard.local',crypt('DG-Demo-Staff-01!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Staff'),(SELECT department_id FROM departments WHERE department_name='Administration')),
 ('Kabir Staff','staff2@docuguard.local',crypt('DG-Demo-Staff-02!',gen_salt('bf',12)),(SELECT role_id FROM roles WHERE role_name='Staff'),(SELECT department_id FROM departments WHERE department_name='Nursing'))
ON CONFLICT(email) DO NOTHING;
