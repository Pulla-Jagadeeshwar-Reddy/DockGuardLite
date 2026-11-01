# DocuGuard Lite Handoff

DocuGuard Lite is a separate repository derived from the full DocuGuard snapshot. Its relational design contains exactly 11 entities: departments, roles, users, document categories, documents, document versions, document permissions, access logs, access overrides, policy assignments and acknowledgments.

It supports authentication and role/document access, PDF/DOCX upload, maker-checker approval, version history, downloads and access logging, expiry, role/department reading assignments, version-specific acknowledgments, emergency access and review, hash-chain audit verification, and a reduced dashboard. PostgreSQL owns relational state. MongoDB stores extracted policy content and flexible page/section metadata. Express alone talks to the databases; Next.js uses the API.

The Lite repository was initialized locally with branch `simplify/er-lite` and has no remote configured. Phase 3 has been approved. Phase 4 implementation is in progress. No tests, builds, migrations or endpoint smoke checks have been run during this implementation phase; consult `TESTING.md` for verification status.
