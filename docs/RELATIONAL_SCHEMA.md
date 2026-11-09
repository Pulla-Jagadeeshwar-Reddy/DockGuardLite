# DocuGuard Lite Relational Schema

Lite implements the approved 11-table PostgreSQL model. The complete attributes, types, nullability, keys, and delete rules are in docs/inputs/docuguard_data_dictionary.md; entity relationships are in docs/inputs/docuguard_er_diagram.mermaid.

| Area | Relations |
|---|---|
| Identity | departments, roles, users |
| Policy and versions | document_categories, documents, document_versions, document_permissions |
| Audit and emergency access | access_logs, access_overrides |
| Reading compliance | policy_assignments, acknowledgments |

## Keys and relationships

- Users reference one role and optionally a department.
- Documents reference a category, owner, and nullable current version. Versions reference their document. 02_alter.sql adds the current-version foreign key after both tables exist.
- Document permissions link a document to a role and record the granting user.
- Access logs reference the actor and document, with optional version and emergency override context.
- Policy assignments target a role, a department, or both. Acknowledgments link a user, assignment, and exact version.

## Database-enforced rules

The DDL enforces required columns, unique emails and names, allowed status/action values, version numbering, maker-checker approval, valid date ranges, permission uniqueness, assignment target presence, acknowledgment uniqueness, break-glass justification/duration and distinct reviewer rules, and foreign-key delete behavior. Triggers verify that acknowledgments match the current approved version. Pending acknowledgments are derived by anti-join.

Access logs use a SHA-256 predecessor chain. A BEFORE INSERT trigger serializes appends with an advisory transaction lock and calculates prev_hash and row_hash. An immutable trigger rejects update/delete; the runtime role also lacks those privileges. verify_audit_chain() returns the first broken log id or NULL and does not persist a verification record.

## Implemented views

- v_document_status_summary: counts documents by status.
- v_expiring_soon: active documents whose current approved version expires within 30 days.
- v_access_activity: daily action and break-glass counts.
- v_break_glass_review_queue: overrides awaiting admin review.
- v_ack_compliance: eligible and acknowledged counts by assignment.
- v_ack_compliance_by_department: department completion totals.

## Implemented functions and triggers

Core SQL functions include fn_accessible_document_ids, fn_access_log_hash, verify_audit_chain, fn_expire_overrides, and fn_expiry_sweep. Reading/workflow functions include fn_assignment_completion, fn_validate_version_transition, fn_after_version_approved, and fn_validate_acknowledgment. Triggers maintain updated_at, enforce legal version transitions, switch the current version and supersede the prior one transactionally, append immutable audit events, and validate acknowledgments.

## Indexes and migration files

03a_indexes_core.sql and 03b_indexes_reading.sql index role/department lookup, document owner/category/status/version, active grants, expiry, audit history, overrides, assignments, and acknowledgments.

The numbered files build the schema in this order: core and reading tables, circular foreign-key alteration, indexes, functions, triggers, views, seeds, runtime privileges, and document seed data. 99_drop.sql removes Lite objects. MongoDB content storage and aggregation are described in docs/NOSQL_VECTOR.md; Lite intentionally has no vector column or vector-search feature.
