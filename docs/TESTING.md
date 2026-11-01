# Testing and Verification — DocuGuard Lite

Verification was run on 2026-11-01. All database mutations used randomly named disposable PostgreSQL and MongoDB databases created by `npm run db:rebuild-test`; the databases were dropped by the validation script. The full repository's databases were not used.

## Results

| Date | Command/check | Result |
|---|---|---|
| 2026-11-01 | `npm install` | Passed; up to date, audited 554 packages. npm reported 19 dependency vulnerabilities (3 low, 16 moderate). |
| 2026-11-01 | `npm run lint` | Passed for backend and frontend TypeScript. |
| 2026-11-01 | `npm run build` | Passed for backend and frontend production builds. |
| 2026-11-01 | `npm run db:rebuild-test` | Passed; migrations, Mongo indexes/content seed, SQL tests, and backend integration suite ran against disposable databases; both databases were removed. |
| 2026-11-01 | Jest/Supertest | Passed: 7 suites, 11 tests. Covers auth/login/logout, user role access, upload/download/maker-checker approval and Mongo compensation, acknowledgment, break-glass/review, audit verification, dashboard, and Mongo aggregation. |
| 2026-11-01 | PostgreSQL SQL tests | Passed: `audit_tamper_demo.sql`, `core_constraints.sql`, and `push_constraints.sql`; includes constraint rejection, maker-checker, access grants, overrides, append-only hash-chain/tamper detection, acknowledgment reopening and recursive version-history query. |
| 2026-11-01 | Endpoint integration smoke checks | Passed through Supertest against Express: `/health`, auth login/logout/me, document upload/detail/approval/download, assignments/acknowledgments, break-glass request/review, audit verify/logs, dashboard and Admin content summary. |
| 2026-11-01 | `docker compose --env-file .env.example config --quiet` | Passed; Compose configuration is valid. |

## Notes

- The first disposable SQL-test attempts found test-fixture issues (ambiguous PL/pgSQL variable names and checksums colliding with seeded checksums). The fixtures were corrected, and the final complete disposable run passed.
- One initial lint run failed because TypeScript was unavailable while an overlapping dependency install was incomplete. After a clean install, lint and build passed.
- No screenshots were fabricated. Capture screenshots from the running Lite application separately if required for presentation.
