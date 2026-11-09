# DocuGuard Lite Demo Guide

A 20-minute walkthrough using the Lite screens, seed accounts and SQL files. Start at Lite root, follow README.md, then open http://localhost:3010/login. Use synthetic data only.

## 1. Schema and integrity - 3 minutes

1. Open docs/inputs/docuguard_er_diagram.mermaid and docs/RELATIONAL_SCHEMA.md. Explain the 11 relations and current-version circular reference.
2. Open database/postgres/01a_schema_core.sql and database/postgres/01b_schema_reading.sql. Point out primary keys, foreign keys, UNIQUE, CHECK and NOT NULL.
3. Open database/postgres/02_alter.sql. Explain why documents.current_version_id is added after document_versions exists.
4. At Lite root, run:
   docker compose exec postgres psql -U docuguard_lite_app -d docuguard_lite -c "SELECT count(*) AS base_tables FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"
   The schema is expected to contain 11 base tables.
5. Show database/postgres/tests/core_constraints.sql and database/postgres/tests/push_constraints.sql. Explain that PostgreSQL rejects invalid data independently of API validation.

## 2. Login, roles and document workflow - 5 minutes

1. Sign in as admin1@docuguard.local using the synthetic demo password in README.md. Navigation includes Overview, Documents, My Policies and Admin links.
2. Open User administration. Show seeded Admin, Doctor, Nurse and Staff roles and departments. Do not expose password hashes.
3. Sign out; sign in as doctor1@docuguard.local. Confirm Admin links are absent, then open Documents and My Policies.
4. From Documents, choose upload to open /documents/new. Upload a synthetic PDF or DOCX from docs/demo-policies/files/pdf/ or docs/demo-policies/files/docx/. Content is stored in MongoDB; metadata and version state are in PostgreSQL.
5. Sign in as admin2@docuguard.local. Open the uploaded document and approve its pending version. The approver must differ from the uploader.
6. Open document detail and download the approved version. Explain that the database trigger appends the access event to the SHA-256 chain.

## 3. Acknowledgments and dashboard - 4 minutes

1. As Admin, open Acknowledgments. Show assignments and department completion.
2. Sign in as nurse2@docuguard.local. Open My Policies and acknowledge a pending current policy.
3. Sign in again as Admin and refresh Acknowledgments. Pending users are derived by anti-join against the current version; pending rows are not stored.
4. Open Overview. Show document status, upcoming expirations and access activity. Admin also sees acknowledgment progress and common terms from approved content.
5. Open docs/QUERIES.md. Explain joins, GROUP BY/HAVING, correlated EXISTS, anti-join, window function and recursive version-history query.

## 4. Emergency access and audit integrity - 5 minutes

1. Sign in as Doctor or Nurse; choose Emergency access.
2. Enter a policy ID supplied by the demo operator, a justification of at least 20 characters, choose a duration up to 24 hours, and submit. Explain the transaction that creates the override and flagged access log.
3. Sign in as a different Admin; open Emergency reviews and review the request. The requester cannot review their own request.
4. Open Audit log, filter by action or document, and click Verify integrity. The result is returned for that request and is not persisted as history.
5. Open database/postgres/04a_functions_core.sql and database/postgres/05a_triggers_core.sql. Explain the advisory transaction lock, previous hash, row hash and immutability trigger.
6. Optional instructor-only tamper demo: run database/postgres/tests/audit_tamper_demo.sql through the disposable SQL test workflow as database owner, never the runtime login. It proves verify_audit_chain() identifies the altered row and rolls the tamper back.

## 5. MongoDB and wrap-up - 3 minutes

1. Open docs/NOSQL_VECTOR.md and database/mongo/indexes.js. MongoDB stores extracted content; PostgreSQL owns policy identity and lifecycle.
2. Open database/mongo/aggregations.js and backend/src/routes/analytics.ts. The Admin API selects eligible current versions in PostgreSQL, then filters the Mongo pipeline by those ids.
3. Summarize constraints, triggers, transactions, role grants and Mongo aggregation as extension points within the 11-entity model.

## Screenshot evidence

The current report contains the screenshots listed in docs/SCREENSHOTS.md. Replace the pending approval image with a post-approval/version-history state, and replace the login-error image at S15 with a real access-denied state if that specific screenshot is required. Use synthetic data only.
