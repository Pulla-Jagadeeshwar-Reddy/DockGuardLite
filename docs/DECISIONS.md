# Lite Design Decisions

1. The pasted simplified Mermaid model is the schema authority. The Chen image is a visual reference only.
2. The Lite repository is a new local Git repository with no remote. The full repository is left untouched.
3. Demo personnel remain the existing seeded departments, roles and users; simplification changes application/database features, not personnel identity or role semantics.
4. PostgreSQL is the source of truth for the 11 relational entities. MongoDB remains a content store for extracted policy versions.
5. Authorization uses role names and per-document grants. Emergency access is a separate time-limited path recorded in the audit log.
6. No schema additions are planned. Lost recursive-query evidence is proposed to be replaced by a recursive walk over document versions; see `SIMPLIFICATION_PLAN.md`.
7. Audit verification without a persisted verification-history row is proposed, subject to user approval.
8. Database names, Compose project/volumes/container identities and host ports will be isolated from the full version during implementation.
9. Lite verification starts empty. Full-version test results do not transfer.
10. **Open schema conflict:** Mermaid contains `DOCUMENT_VERSIONS.vector_id`; prose says remove it. Per precedence, the draft retains the nullable unique field, unused. This needs explicit resolution before SQL is rewritten.
