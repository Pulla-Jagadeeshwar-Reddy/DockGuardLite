# DocuGuard Lite Handoff

DocuGuard Lite is a new, separate repository derived from the full DocuGuard snapshot. Its target relational design has 11 entities: departments, roles, users, document categories, documents, document versions, document permissions, access logs, access overrides, policy assignments and acknowledgments.

The intended workflows are authentication and role/document access, PDF/DOCX upload, maker-checker approval, version history, download/access logging, expiry, role/department assignments, version-specific acknowledgments, break-glass emergency access/review, audit hash verification and a reduced dashboard. PostgreSQL owns relational state. MongoDB stores extracted policy content and flexible page/section metadata. Express alone talks to the databases; Next.js uses the API.

The current branch is `simplify/er-lite`. Two commits establish the imported snapshot and repository origin. Documentation is being revised before any database/application code changes. Phase 3 must end with an explicit user approval before implementation begins. No remote is configured and none should be added by the agent.

The authoritative Mermaid supplied in the task includes `DOCUMENT_VERSIONS.vector_id`, whereas prose says to drop it. Mermaid takes precedence under the user rule, so it is retained in the draft schema contract pending clarification. The simplified repository is not yet runnable side by side; config and source code are inherited and await the approved implementation phase.

No lite tests/builds have been run. See `TESTING.md` for the empty verification record and `SIMPLIFICATION_PLAN.md` for inventory and approval questions.
