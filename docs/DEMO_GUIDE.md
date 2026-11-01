# DocuGuard Lite Demo Guide

This is a 15–20 minute walkthrough for the simplified target. The interface and database work are not yet simplified; use the steps after Phase 4 implementation and Phase 6 verification.

## 1. Model and data integrity (3 minutes)

1. Show `docs/inputs/docuguard_er_diagram.mermaid` and the Chen diagram image.
2. Trace `USERS` to `ROLES`/`DEPARTMENTS`, then `DOCUMENTS` to its versions and current-version pointer.
3. Show `02_alter.sql` after it has been simplified and explain why the circular FK is added after both tables exist.
4. Show CHECK/FK/UNIQUE examples and the SQL negative tests.

## 2. Authentication and document lifecycle (5 minutes)

1. Sign in with one of the synthetic accounts in README.
2. Compare role navigation and document grants using a Doctor/Nurse and Admin account.
3. Upload a synthetic PDF or DOCX and show its pending version.
4. Sign in as another Admin and approve it; show maker-checker and version history.
5. Download the permitted file and show its access log row.

## 3. Audit and emergency access (4 minutes)

1. Open the Admin audit page, inspect filters and hash fields, then verify integrity.
2. Show `verify_audit_chain()` and explain the advisory lock, `prev_hash`, SHA-256 hash, immutable trigger and runtime grants.
3. As a Doctor or Nurse, request temporary access with a valid justification.
4. As a different Admin, review the request and show the flagged audit log entry.

## 4. Acknowledgments and dashboard (4 minutes)

1. As Admin, assign an approved policy to a role or department.
2. As a targeted user, open My Policies and acknowledge the current version.
3. Return as Admin and show completed/pending totals by department.
4. Approve a later version and explain why the new version is pending again.
5. Show the dashboard's live document status, expiry and access activity summaries.

## 5. MongoDB content and DBMS concepts (3 minutes)

1. Show the MongoDB `document_contents` record and its linked PostgreSQL version id.
2. Demonstrate the content read/write/update/delete lifecycle, including compensation/orphan cleanup in code.
3. Show the Admin category/term aggregation if approved and implemented.
4. End with joins, the pending-user anti-join, GROUP BY/HAVING, and the recursive version-history query from `docs/QUERIES.md`.

All sample policies and users are synthetic. Never upload real patient records.
