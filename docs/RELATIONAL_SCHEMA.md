# DocuGuard Lite Relational Schema

The lite target has the following 11 PostgreSQL entities. The attribute-level contract and ER relationships are in `docs/inputs/docuguard_data_dictionary.md` and `docs/inputs/docuguard_er_diagram.mermaid`.

| Area | Relations |
|---|---|
| Identity | `departments`, `roles`, `users` |
| Policy and versions | `document_categories`, `documents`, `document_versions`, `document_permissions` |
| Audit and emergency access | `access_logs`, `access_overrides` |
| Reading compliance | `policy_assignments`, `acknowledgments` |

## Keys and relationships

- `users.role_id` references `roles`; `users.department_id` references `departments` and becomes NULL if a department is removed.
- `documents.category_id` and `documents.owner_id` refer to category and owner. `documents.current_version_id` points to a version and is added with ALTER after both sides exist. `document_versions.document_id` points back to its document.
- `document_permissions` grants one role one access level on a document, with the user who granted it recorded.
- `access_logs` records actor, document, optional version and optional emergency override. Its references restrict deletion so audit history does not lose context.
- `access_overrides` records requester, document and optional distinct reviewer.
- `policy_assignments` targets a role, department, or both. `acknowledgments` ties a user and assignment to a particular document version.

## Important constraints and behavior

DDL enforces role and status enumerations, required values, unique emails/names/version numbers/grants/acknowledgments, date ordering, maker-checker, assignment target presence, break-glass limits, reviewer/requester distinction, and foreign-key delete behavior. Pending acknowledgments are computed, not stored. Version approval and expiry are handled by triggers/functions. Access logs use a SHA-256 predecessor chain, immutable trigger, and restricted runtime grants.

The corrected simplified model omits 
## Views, functions and indexes planned

Views will summarize document status, active documents expiring soon, access activity, emergency review queue, acknowledgment completion, and acknowledgment completion by department. Functions will cover accessible document ids, audit hash calculation/verification, override expiry, and version expiry. Triggers will maintain updated timestamps, legal version transitions/current version, append-only hash logs, and acknowledgment behavior only where it does not require removed storage. Indexes will support owner/category/status, active role grants, expiry, access history, active overrides, assignment/ack joins, and audit sequence.

## Migration mapping

The existing numbered migration runner will be retained, with DDL is split between core/reading schema, circular-FK ALTER, indexes, functions, triggers, views, seeds, runtime role and checksum migration. Exact object inventory and change mapping are in `SIMPLIFICATION_PLAN.md`.

