# DocuGuard Project Handoff Report

**Prepared:** 2026-10-31  
**Purpose:** Transfer project context to another LLM or teammate. Treat this report as a summary; verify current files before making changes.

## 1. Project at a glance

DocuGuard is a local-first Healthcare Policy & Compliance Intelligence Platform for a university DBMS project. It manages policy documents and versions, permissions, approvals, acknowledgments, regulatory coverage, emergency break-glass access, and tamper-evident audit history. It supports keyword, semantic, and hybrid policy search. All supplied policy/regulation examples are synthetic or illustrative; it is not a clinical decision system.

The educational priority is visible database design and behavior: relational DDL, keys and constraints, triggers/functions/views, transactions, joins and aggregation, recursive CTEs, MongoDB CRUD/aggregation, pgvector retrieval, and a demonstrable UI/API.

## 2. Required architecture and implementation

- **Frontend:** Next.js App Router, TypeScript, Tailwind, React Hook Form/Zod, Recharts and React Flow where used.
- **API:** Express.js, TypeScript, Zod validation, parameterized PostgreSQL SQL via `pg`, and the official MongoDB driver.
- **Databases:** PostgreSQL 16 (`pgvector` and `pgcrypto` extensions) and MongoDB 7, launched with Docker Compose.
- **Security:** Express is the only database client. Passwords are bcrypt hashes; sessions use JWT in an HTTP-only cookie. Express reloads user role/permissions from PostgreSQL and applies auth/RBAC middleware. SQL search filters by accessible document ids before content snippets are fetched from MongoDB. Uploads are private, allow-listed PDF/DOCX, and use random names. Audit rows are append-only for the runtime role.
- **Embeddings:** local `Xenova/all-MiniLM-L6-v2`, 384 dimensions, normalized; no external API key or LLM/RAG feature.

Architecture explanation and diagram: `docs/ARCHITECTURE.md`. Setup and run instructions: `README.md`.

## 3. Database responsibilities

### PostgreSQL is the source of truth for

Users, departments, roles, permissions, document metadata and versions, role/document access grants, access overrides, access logs and audit verification records, notifications, search metadata, acknowledgments, policy assignments, regulations, controls, control mappings, document references, similarity pairs, and vector/full-text search metadata.

The DDL is split across numbered files in `database/postgres/`:

- `01a_schema_core.sql`, `01b_schema_search.sql`: tables and constraints.
- `02_alter.sql`: circular document/current-version foreign key added after both tables exist.
- `03a_indexes_core.sql`, `03b_indexes_search.sql`: ordinary, GIN, and HNSW indexes.
- `04a_functions_core.sql`, `04b_functions_search.sql`: access, audit, expiry, and coverage functions.
- `05a_triggers_core.sql`, `05b_triggers_search.sql`: audit, version, notification and acknowledgment workflow triggers.
- `06a_views_core.sql`, `06b_views_search.sql`: dashboard, acknowledgment and coverage views.
- `07a_seed_core.sql`, `07b_seed_search.sql`: synthetic demo rows.
- `08_auth_runtime.sql`, `09_documents.sql`: runtime DB role and checksum enforcement.
- `99_drop.sql`: schema-object teardown for a deliberate local rebuild.

Database design explanations: `docs/RELATIONAL_SCHEMA.md` and `docs/inputs/docuguard_data_dictionary.md`. ER model: `docs/inputs/docuguard_er_diagram.mermaid`.

### MongoDB stores

`document_contents` stores extracted document/version content, pages, sections, and extraction metadata. `document_chunks` stores chunk text and metadata. MongoDB indexes are set up by `database/mongo/indexes.js`; synthetic content is seeded by `database/mongo/seed.js`. Ingestion code is in `backend/src/services/ingest.ts`; it includes content insertion, read/lookup, linkage/update, compensation deletion, and orphan cleanup. Admin analytics uses Mongo aggregation (`$match`, `$facet`, `$unwind`, `$group`) in `backend/src/routes/analytics.ts` and `database/mongo/aggregations.js`.

### pgvector and full-text search

`document_chunks` in PostgreSQL stores the Mongo chunk id, `vector(384)`, and `tsvector`. HNSW with cosine operations supports semantic retrieval; GIN supports English full-text search. Search implementation: `backend/src/routes/search.ts`. Hybrid results use Reciprocal Rank Fusion with k=60. MongoDB supplies snippets only after PostgreSQL has filtered/ranked permitted documents. Design details: `docs/NOSQL_VECTOR.md` and query samples: `docs/QUERIES.md`.

## 4. Implemented application features

- Login, logout, session/me, bcrypt passwords, JWT cookie, user administration, role/permission middleware.
- PDF/DOCX upload, extraction, Mongo storage/chunking, PostgreSQL document/version records, maker-checker approval, version history, downloads/access logging, checksums, compensation/orphan cleanup.
- Notifications, dashboard summaries/charts, expiry sweep and warning notifications.
- Permission-aware keyword, semantic and hybrid search; snippets; related/similar policies.
- My Policies, role/department assignments, version-specific acknowledgment, pending users computed by anti-join, department compliance summaries.
- Illustrative regulation/control mapping and coverage matrix; only active policies with an approved, unexpired current version count as covered.
- Break-glass emergency access: time-limited override with justification, flagged access log and admin notifications in one transaction; Admin review.
- Audit hash chain with advisory lock, SHA-256 row hashes, immutable trigger/grants, integrity verification and audit result history.
- Admin dependency graph and impact analysis via recursive CTE with path-based cycle prevention.

API route modules live in `backend/src/routes/`. Frontend pages live in `frontend/src/app/`.

## 5. Work completed and project state

- The implementation was delivered through phases 0–7 and integrated Pull/Push work. Local Git history shows phase branches and merged PRs on `origin/main`.
- Current branch at report time: `pull/final-integration-fixes`, tracking `origin/pull/final-integration-fixes`.
- Current HEAD: `9d0010b fix(integration): complete final verification and demo data`.
- `origin/main` points to `648b759 docs: update integrated verification status` in the local refs observed during review. Current branch is one commit ahead of that ref according to the recent history; confirm remote state before pushing/PR work.
- Working tree had one modified generated file, `frontend/next-env.d.ts` (Next.js type reference changed from `.next/types` to `.next/dev/types`). It was not intentionally edited as part of the data population. Inspect it before committing; do not discard it without checking with the owner.
- No code changes were made during the later DB population request; the population was done against local databases.

## 6. Demo database population already performed

The user requested realistic demo policies/compliance data while specifically forbidding changes to personnel data. The population was performed without changing the existing personnel rows:

- Before/after fingerprints matched for the existing four departments, four roles, and eight users. Personnel data was left unchanged.
- Added five policy categories, 12 synthetic policies and their versions/permissions, illustrative regulations/controls/mappings, references, and policy assignments.
- Generated/seeded PDF and DOCX assets and Mongo content/chunks. Existing approved demo policies were embedded locally; a similarity cache was rebuilt.
- Added sample acknowledgments, pending emergency access overrides with flagged audit events, and realistic notifications.
- Ensured every existing user had at least one assignment.
- Recorded state after the operation: 12 policies (11 approved, one expired); 2 pending emergency reviews; 20 controls; coverage summary DPDP 4/5, HIPAA 5/5, JCI 5/5, NABH 5/5; 11 PostgreSQL vector chunks and 12 Mongo content/chunk records. Earlier old policies without Mongo chunks were skipped for embeddings.
- Admin/API smoke check previously returned assignment, emergency review, regulation/control, acknowledgment summary, and My Policies data; Nurse My Policies returned a row. Backend health had returned both databases true during that operation.
- These are results recorded from that prior local run, not a claim that the current Docker services are running now.

The user had earlier asked to avoid modifying personnel, and that condition was checked with the row fingerprints.

## 7. Verification evidence recorded in the repository

`docs/TESTING.md` records verification on **2026-10-29**:

- `npm run lint`: passed (backend and frontend TypeScript).
- `npm run build`: passed; backend compiled and Next.js generated 15 app routes.
- `npm run db:rebuild-test`: passed on disposable PostgreSQL and MongoDB databases; migration/seed, embeddings/model check, API tests, SQL tests completed and temporary DBs removed.
- Jest/Supertest: 8 suites, 17 tests passed.
- PostgreSQL constraint/trigger/Push tests and audit tamper rehearsal passed.
- Embedding check: 384 finite dimensions, norm 1.0000.
- PDF files validated/rendered; DOCX packages validated for non-empty text, but visual rendering was not completed because LibreOffice was unavailable.
- Screenshots were not captured.
- Registry-backed vulnerability audit was not verified because npm registry access failed; installation reported five low-severity advisories.

Do not claim these checks were rerun unless a new run is performed. The test report also notes that arbitrary infrastructure failure injection for Mongo-to-PostgreSQL compensation was not simulated; duplicate-check compensation was tested.

## 8. Rubric coverage reviewed

The user supplied 14 weighted categories adding to 50 marks. The repository has evidence for each:

1. ER diagram: Mermaid file under `docs/inputs/`.
2. Relational schema/keys/relations/constraints: `docs/RELATIONAL_SCHEMA.md`, data dictionary, SQL DDL.
3. SQL DDL: numbered PostgreSQL migrations and negative SQL constraint tests.
4. NoSQL/vector database creation: Mongo setup/indexes plus PostgreSQL pgvector extension/index.
5. Technology justification: README, architecture and NoSQL/vector docs.
6. DML: SQL seeds, API-backed workflows, and query examples.
7. Nested/correlated/recursive/join SQL: query guide, search and dependency route SQL, views.
8. Advanced SQL: database functions, triggers, CTEs, transactions and views.
9. NoSQL/vector feature CRUD: Mongo content ingest/read/update/delete/cleanup, aggregations, vector search.
10. Next.js interface: application pages under `frontend/src/app/`.
11. Backend/API integration: Express routes, DB config, frontend API helper/proxy.
12. Authentication, two roles and database RBAC: auth routes/middleware, roles/permissions tables and role-aware UI.
13. Documentation/GitHub: root README, docs, commits/branches/merged PR history.
14. Originality/contribution/viva: project workflows and ownership docs exist, but an individual student's live explanation/modification ability must be demonstrated.

More detailed rubric mapping: `docs/RUBRIC_CHECKLIST.md`. Demo sequence: `docs/DEMO_GUIDE.md`. Screenshot capture list: `docs/SCREENSHOTS.md`.

## 9. Known discrepancy to address

**Similar-document score threshold mismatch:** requirements and `docs/NOSQL_VECTOR.md` describe storing pairs with score at least **0.85**, but `backend/src/services/similar-documents.ts` currently filters at **0.15**. This is the clearest known correctness deviation from the stated requirements. Resolve the value and any related tests/docs before claiming strict compliance. Do not silently update behavior as part of an unrelated task.

## 10. Useful commands for the next LLM/operator

Run from the repository root in PowerShell:

```powershell
Copy-Item .env.example .env   # only if .env does not already exist; do not overwrite real local config
# Fill local values in .env, then:
docker compose up -d
npm install
npm run db:apply
npm run db:mongo:indexes
npm run db:mongo:seed
npm run db:embeddings
npm run dev
```

For recorded verification commands, see `docs/TESTING.md` and README. `npm run db:rebuild` drops objects from the configured public schema; only use it for disposable local data. `npm run db:rebuild-test` uses disposable DBs according to README/TESTING.md.

## 11. Instructions for whoever continues the work

1. Begin with `git status --short --branch`; preserve the existing `frontend/next-env.d.ts` change unless the owner directs otherwise.
2. Read the exact requirement/docs and implementation before modifying anything.
3. Fix the similarity threshold mismatch as a targeted change, with appropriate test/document update, if authorized by the owner.
4. Do not publish or push changes without the user's instruction. The owner previously preferred to create PRs themselves.
5. Do not modify personnel DB rows when updating the demo data unless explicitly asked.
6. Never claim a test was run without actually running it; report current results and any environment limitation accurately.
7. Keep secrets and populated `.env` out of Git. Do not expose real credentials in handoff text.

## Key references

- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/RELATIONAL_SCHEMA.md`
- `docs/NOSQL_VECTOR.md`
- `docs/QUERIES.md`
- `docs/TESTING.md`
- `docs/RUBRIC_CHECKLIST.md`
- `docs/OWNERSHIP.md`
- `docs/DEMO_GUIDE.md`
- `docs/SCREENSHOTS.md`
- `docs/inputs/docuguard_er_diagram.mermaid`
- `docs/inputs/docuguard_data_dictionary.md`
