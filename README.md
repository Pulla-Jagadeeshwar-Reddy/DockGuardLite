# DocuGuard Lite

A smaller local healthcare policy workflow for a university DBMS project. This is a separate repository; the full DocuGuard repository remains an untouched archive.

## Prerequisites

- Node.js 22 and npm
- Docker Desktop with Docker Compose
- Ports 55432, 27018, 4010 and 3010 available

## Local setup

1. Copy `.env.example` to `.env`; set local PostgreSQL/Mongo passwords and a random JWT secret of at least 32 characters.
2. Start the isolated databases: `docker compose up -d`.
3. Install packages: `npm install`.
4. Apply PostgreSQL schema and demo relational data: `npm run db:rebuild` (this resets only Compose database `docuguard_lite`; do not change its `.env` database name).
5. Configure the runtime role: `npm run db:auth`.
6. Create Mongo indexes and seed extracted content: `npm run db:mongo:indexes` then `npm run db:mongo:seed`.
7. Start Express and Next.js: `npm run dev`.
8. Open `http://localhost:3010/login`; health is `http://localhost:4010/health`.

Docker Compose uses project `docuguard-lite`, explicit containers and volumes, PostgreSQL host port `55432`, and MongoDB host port `27018`. The API and frontend use `4010` and `3010`. These are separate from the full project's default ports and volumes. The Lite Mongo URI and PostgreSQL host connection are in `.env.example`.

For an isolated disposable database test, use `npm run db:rebuild-test`. It must never point at the full project's databases. Run `npm run lint` and `npm run build` for static checks.

## Demo accounts

These are synthetic accounts inherited from the project seed; passwords are throwaway demo values stored in PostgreSQL as bcrypt hashes.

| Role | Email | Demo password |
|---|---|---|
| Admin | `admin1@docuguard.local` | `DG-Demo-Admin-01!` |
| Admin | `admin2@docuguard.local` | `DG-Demo-Admin-02!` |
| Doctor | `doctor1@docuguard.local` | `DG-Demo-Doctor-01!` |
| Doctor | `doctor2@docuguard.local` | `DG-Demo-Doctor-02!` |
| Nurse | `nurse1@docuguard.local` | `DG-Demo-Nurse-01!` |
| Nurse | `nurse2@docuguard.local` | `DG-Demo-Nurse-02!` |
| Staff | `staff1@docuguard.local` | `DG-Demo-Staff-01!` |
| Staff | `staff2@docuguard.local` | `DG-Demo-Staff-02!` |

## Documentation

- `docs/ARCHITECTURE.md` — components and request flow.
- `docs/RELATIONAL_SCHEMA.md` and `docs/inputs/` — ER model and database constraints.
- `docs/QUERIES.md` — educational SQL/Mongo examples.
- `docs/NOSQL_VECTOR.md` — MongoDB content model and aggregation.
- `docs/RUBRIC_CHECKLIST.md`, `docs/OWNERSHIP.md`, `docs/DEMO_GUIDE.md` — presentation evidence.
- `docs/TESTING.md` — verification results, updated only after actual runs.
- `docs/SIMPLIFICATION.md` and `docs/SIMPLIFICATION_PLAN.md` — change rationale and impact record.

All policies and users are synthetic. Do not upload patient data. `.env`, local uploads, Docker volumes and build output are ignored and must not be committed.
