# DocuGuard Lite Handoff

DocuGuard Lite is a separate project derived from the full DocuGuard snapshot. It follows the approved 11-table model: departments, roles, users, document categories, documents, document versions, document permissions, access logs, access overrides, policy assignments and acknowledgments.

The application supports authentication and role/document access, PDF/DOCX upload, maker-checker approval, version history, downloads and access logging, expiry, role/department reading assignments, version-specific acknowledgments, emergency access and review, hash-chain audit verification, and a reduced dashboard. PostgreSQL owns relational state. MongoDB stores extracted policy content and flexible page/section metadata. Express alone talks to the databases; Next.js uses the API.

The Lite branch is simplify/er-lite in https://github.com/Pulla-Jagadeeshwar-Reddy/DockGuardLite. The final report is DocuGuard_Lite_DBMS_Mini_Project_Report_Final.docx. Verification was rerun on 2026-11-09; npm install, lint, build, the isolated PostgreSQL/MongoDB workflow, 7 Jest/Supertest suites (11 tests), SQL tests, and endpoint integration tests passed. See docs/TESTING.md for exact recorded results.

Remaining team/submission work: complete the report cover fields; replace the S7 pending-approval screenshot with the post-approval state; replace S15 with an authorization-denial screen if required; add the teammate's own Lite commits and collaborator access; confirm the instructor accepts application-enforced role/document access as database-backed RBAC.
