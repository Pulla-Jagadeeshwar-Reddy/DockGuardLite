# Lite Design Decisions

1. The pasted simplified Mermaid model is the schema authority. The Chen image is a visual reference only.
2. The Lite repository is a new local Git repository with no remote. The full repository is left untouched.
3. Demo personnel remain the existing seeded departments, roles and users; simplification changes application/database features, not personnel identity or role semantics.
4. PostgreSQL is the source of truth for the 11 relational entities. MongoDB remains a content store for extracted policy versions.
5. Authorization uses role names and per-document grants. Emergency access is a separate time-limited path recorded in the audit log.
6. No schema additions are permitted. The recursive CTE demo uses existing `document_id` and `version_number` columns to walk a document's ordered version history.
7. Audit verification keeps the hash chain and function/endpoint but returns a non-persisted result.
8. Database names, Compose project/volumes/container identities and host ports will be isolated from the full version during implementation.
9. Lite verification starts empty. Full-version test results do not transfer.

