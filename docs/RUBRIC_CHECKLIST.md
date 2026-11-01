# Rubric Evidence Checklist — DocuGuard Lite

This maps the supplied 50-mark rubric to the simplified target. The lite implementation has not yet been completed or verified; all entries below are evidence targets, not claims of a passing grade.

| Metric | Marks | Planned evidence |
|---|---:|---|
| ER diagram | 2 | `inputs/docuguard_er_diagram.mermaid` and Chen reference image. |
| Relational schema, keys, relationships, constraints | 3 | `RELATIONAL_SCHEMA.md`, `inputs/docuguard_data_dictionary.md`, numbered DDL. |
| SQL DDL with constraints | 4 | PostgreSQL CREATE/ALTER scripts and negative constraint tests. |
| NoSQL database creation | 4 | MongoDB 7 content collection, indexes and setup command. |
| Technology justification | 1 | `ARCHITECTURE.md`, `NOSQL_VECTOR.md`, README. |
| DML operations | 4 | Seed and API create/read/update/delete workflows with parameterized SQL. |
| Nested/correlated/recursive/join SQL | 4 | `QUERIES.md`: permission-filtered joins, acknowledgment anti-join, expiry predicate, version-history CTE. |
| Advanced SQL: functions, triggers, CTE | 6 | Access/audit/expiry functions, version and audit triggers, views, transactions and recursive version lineage. |
| NoSQL feature and CRUD | 7 | Mongo content ingestion/read/link/update/compensation cleanup plus approved metadata aggregation. |
| Next.js interface | 3 | Login, role-specific document, Admin, acknowledgment, emergency and audit pages. |
| Backend/API/database integration | 2 | Express routes with parameterized PostgreSQL access and Mongo content lookups. |
| Authentication, two roles, database RBAC | 4 | bcrypt/JWT, roles in PostgreSQL, `DOCUMENT_PERMISSIONS`, role checks and API denial tests. |
| Documentation and Git/GitHub | 2 | README, architecture/schema/query/testing/demo docs and local Git history. No remote will be configured by this agent. |
| Originality/contribution/modification/viva | 4 | Break-glass transaction, hash-chain audit and versioned acknowledgments; `OWNERSHIP.md`, student commits and live explanation. |

The rubric's NoSQL category can be evidenced through MongoDB. The separate vector/retrieval implementation is not part of the lite feature plan. The simplified project still needs the instructor's acceptance of this substitution.
