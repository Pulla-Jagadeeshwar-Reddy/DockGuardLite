-- Configure a restricted API login using the secret supplied to psql.
ALTER ROLE docuguard_runtime LOGIN PASSWORD :'runtime_password';
GRANT USAGE ON SCHEMA public TO docuguard_runtime;
GRANT SELECT ON roles,departments TO docuguard_runtime;
GRANT SELECT,INSERT,UPDATE ON users TO docuguard_runtime;
GRANT USAGE,SELECT ON SEQUENCE users_user_id_seq TO docuguard_runtime;
