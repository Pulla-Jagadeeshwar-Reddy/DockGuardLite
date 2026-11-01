# DocuGuard Lite

A simplified, local-first healthcare policy workflow for the university DBMS project. This repository is separate from the full DocuGuard archive. It is currently at the documentation/approval-plan stage; the inherited application and Docker files are not yet the side-by-side Lite configuration.

## Planned local setup (after implementation)

Prerequisites: Node.js 22, npm, Git and Docker Desktop with Compose.

The Lite environment will use an isolated Compose project named `docuguard-lite`, PostgreSQL database `docuguard_lite`, MongoDB database `docuguard_lite`, PostgreSQL host port `55432`, MongoDB host port `27018`, API port `4010` and frontend port `3010`. These values are targets and will be applied to Compose, `.env.example`, backend and frontend config only after Phase 3 approval. They keep Lite separate from the full app's usual ports and data volumes.

Once implementation is complete, the intended workflow is:

1. Copy `.env.example` to `.env` and set local passwords/JWT secret.
2. `docker compose -p docuguard-lite up -d`
3. `npm install`
4. Apply the Lite PostgreSQL migrations and MongoDB indexes/seed using the documented commands.
5. `npm run dev`
6. Open `http://localhost:3010/login`; API health will use `http://localhost:4010/health`.

Do not use the inherited `db:rebuild` command until the Lite scripts explicitly target the isolated `_lite` database. It can destroy the selected schema. Use only disposable databases for tests.

## Demo accounts

The full snapshot contains synthetic seeded Admin, Doctor, Nurse and Staff accounts. The Lite seed must preserve the same people, roles and departments. After the Lite seed is implemented, use the synthetic credentials in the table below (copied from the prior demo seed); never use these for real services.

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

## Security and data

Only `.env.example` belongs in Git. `.env`, Docker volumes, uploads, dependency directories and build output are ignored/excluded. Never upload real patient data. The supplied policy files are synthetic examples.

## Documentation

- `docs/ARCHITECTURE.md` — components and request flow.
- `docs/RELATIONAL_SCHEMA.md` and `docs/inputs/` — ER/schema contract.
- `docs/QUERIES.md` — educational query examples.
- `docs/NOSQL_VECTOR.md` — Mongo content model.
- `docs/RUBRIC_CHECKLIST.md`, `docs/OWNERSHIP.md`, `docs/DEMO_GUIDE.md` — presentation guidance.
- `docs/TESTING.md` — currently empty verification record.
- `docs/SIMPLIFICATION_PLAN.md` — inventory, rubric impact, and approval gate.
