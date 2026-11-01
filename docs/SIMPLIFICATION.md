# Simplification Record

The purpose of this repository is to preserve the core policy-document workflow in a teachable 11-table model. The full DocuGuard project remains separately archived. This record is the only general documentation inventory of removed capabilities; see `SIMPLIFICATION_PLAN.md` for dependency-level detail and approval questions.

## Relational entities excluded from the Lite target

- `PERMISSIONS` and `ROLE_PERMISSIONS`: fine-grained permission catalog/junction removed in favor of roles and per-document grants.
- `NOTIFICATIONS`: message inbox removed; pending work is shown by direct queue and anti-join queries.
- `SEARCH_LOGS`: search feature/log removed.
- `AUDIT_INTEGRITY_CHECKS`: verification-history relation removed; verification returns a non-persisted result.
- `REGULATIONS`, `CONTROLS`, `DOCUMENT_CONTROL_MAP`: regulatory coverage data and matrix removed.
- `DOCUMENT_CHUNKS`: stored search chunks removed; MongoDB retains complete extracted version content.
- `DOCUMENT_REFERENCES`: policy dependency edges and impact graph removed.
- `SIMILAR_DOCUMENTS`: pair cache removed.

The `DOCUMENT_VERSIONS.vector_id` column from the initially pasted model was also excluded after the owner corrected the target.

## Application capabilities excluded

Keyword/semantic/hybrid retrieval and vector indexing, related-policy results, the message inbox, dependency graph/impact analysis, regulatory coverage/mapping, and stored audit-verification history are outside the Lite scope. Retained workflows are specified in `README.md` and `ARCHITECTURE.md`.

## Schema ambiguity

The initially supplied Mermaid included `DOCUMENT_VERSIONS.vector_id`. The owner corrected the model and approved dropping the field, so the Lite ER model, data dictionary and SQL omit it.
