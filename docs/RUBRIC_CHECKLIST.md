# Rubric Evidence Checklist - DocuGuard Lite

This maps each of the 14 supplied grading categories to evidence that exists in this repository. It identifies implementation evidence; the instructor assigns marks. Verification results are in TESTING.md.

| Evaluation metric | Marks | Evidence in Lite |
|---|---:|---|
| ER diagram | 2 | docs/inputs/docuguard_er_diagram.mermaid; docs/inputs/docuguard_chen_er_simple.png |
| Relational schema, keys, relationships and constraints | 3 | docs/RELATIONAL_SCHEMA.md; docs/inputs/docuguard_data_dictionary.md; database/postgres/01a_schema_core.sql; database/postgres/01b_schema_reading.sql; database/postgres/02_alter.sql |
| SQL DDL with constraints | 4 | database/postgres/01a_schema_core.sql; database/postgres/01b_schema_reading.sql; database/postgres/02_alter.sql; database/postgres/tests/core_constraints.sql; database/postgres/tests/push_constraints.sql |
| NoSQL database creation | 4 | docker-compose.yml (MongoDB 7); database/mongo/indexes.js; database/mongo/seed.js; docs/NOSQL_VECTOR.md |
| Technology justification | 1 | docs/ARCHITECTURE.md; docs/NOSQL_VECTOR.md; README.md |
| DML operations | 4 | database/postgres/07a_seed_core.sql; database/postgres/07b_seed_documents.sql; database/postgres/07c_seed_reading.sql; database/postgres/07d_seed_emergency.sql; backend/src/routes/documents.ts; backend/src/routes/users.ts |
| Nested, correlated, recursive and join SQL queries | 4 | docs/QUERIES.md; backend/src/routes/documents.ts; backend/src/routes/acknowledgments.ts; database/postgres/tests/push_constraints.sql (recursive version-history CTE) |
| Advanced SQL: functions, triggers and CTE | 6 | database/postgres/04a_functions_core.sql; database/postgres/04b_functions_reading.sql; database/postgres/05a_triggers_core.sql; database/postgres/05b_triggers_reading.sql; database/postgres/06a_views_core.sql; database/postgres/06b_views_reading.sql; database/postgres/tests/push_constraints.sql |
| NoSQL feature and CRUD | 7 | backend/src/services/ingest.ts; backend/src/routes/documents.ts; backend/src/routes/analytics.ts; database/mongo/indexes.js; database/mongo/seed.js; database/mongo/aggregations.js; backend/test/documents.test.mjs; backend/test/mongo-analytics.test.mjs |
| Next.js interface | 3 | frontend/src/app/login/page.tsx; frontend/src/app/(protected)/layout.tsx; frontend/src/app/(protected)/dashboard/page.tsx; frontend/src/app/(protected)/documents/page.tsx; frontend/src/app/(protected)/documents/[id]/page.tsx; frontend/src/app/(protected)/documents/new/page.tsx; frontend/src/app/(protected)/my-policies/page.tsx; frontend/src/app/(protected)/break-glass/page.tsx; frontend/src/app/(protected)/admin/users/page.tsx; frontend/src/app/(protected)/admin/acknowledgments/page.tsx; frontend/src/app/(protected)/admin/break-glass/page.tsx; frontend/src/app/(protected)/admin/audit/page.tsx |
| Backend/API and database integration | 2 | backend/src/app.ts; backend/src/config/databases.ts; backend/src/routes/documents.ts; backend/src/routes/acknowledgments.ts; backend/src/routes/overrides.ts; backend/src/routes/audit.ts; backend/src/routes/dashboard.ts; backend/src/routes/analytics.ts |
| Authentication, two or more roles and database-backed role/document authorization | 4 | backend/src/routes/auth.ts; backend/src/middleware/auth.ts; backend/src/routes/users.ts; database/postgres/01a_schema_core.sql (roles and document_permissions); database/postgres/04a_functions_core.sql (fn_accessible_document_ids); database/postgres/08_auth_runtime.sql; backend/test/auth.test.mjs |
| Documentation and Git/GitHub | 2 | README.md; docs/ARCHITECTURE.md; docs/RELATIONAL_SCHEMA.md; docs/QUERIES.md; docs/TESTING.md; docs/OWNERSHIP.md; docs/DEMO_GUIDE.md; docs/RUBRIC_CHECKLIST.md; docs/SCREENSHOTS.md; local Git history; GitHub repository Pulla-Jagadeeshwar-Reddy/DockGuardLite, branch simplify/er-lite. |
| Originality, individual contribution, modification and viva | 4 | backend/src/routes/overrides.ts; backend/src/routes/audit.ts; database/postgres/04a_functions_core.sql; database/postgres/05a_triggers_core.sql; database/postgres/06b_views_reading.sql; docs/OWNERSHIP.md; docs/WORK_SPLIT.md. Individual credit should be supported by each student's own commits and live explanation. |

## Limits to explain during evaluation

- PostgreSQL stores the four application roles and per-document role grants. Express checks role names and SQL permission queries check document grants. This is application authorization backed by relational data, not four separate PostgreSQL login roles.
- MongoDB stores extracted policy content and supports category/keyword aggregation. PostgreSQL owns users, authorization, versions and workflow state.
- The recursive query follows consecutive document_versions.version_number values using existing columns. It adds no relation.
- The NoSQL rubric path is implemented with MongoDB content CRUD and aggregation. Lite has no vector database, semantic search, notifications, regulation mapping or dependency graph.


The NoSQL/Vector rubric wording is treated as alternatives here: MongoDB satisfies the NoSQL option. The Lite ER model was approved without vector entities or columns.
