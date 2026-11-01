# DocuGuard Lite — Data Dictionary

This dictionary describes the 11 relational entities in `docuguard_er_diagram.mermaid`. It records SQL types, keys, nullability, checks, defaults, and referential actions. `DOCUMENT_VERSIONS.vector_id` is retained here because the authoritative Mermaid supplied for this project includes it; this conflicts with the prose instruction to drop it and is awaiting a design decision. No lite application behavior is planned around that field unless the target model is clarified.

## DEPARTMENTS
| Column | SQL type | Constraints |
|---|---|---|
| department_id | SERIAL | PRIMARY KEY |
| department_name | VARCHAR(100) | NOT NULL, UNIQUE |
| description | TEXT | NULL allowed |

## ROLES
| Column | SQL type | Constraints |
|---|---|---|
| role_id | SERIAL | PRIMARY KEY |
| role_name | VARCHAR(50) | NOT NULL, UNIQUE, CHECK IN ('Admin','Doctor','Nurse','Staff') |
| description | TEXT | NULL allowed |

## USERS
| Column | SQL type | Constraints |
|---|---|---|
| user_id | SERIAL | PRIMARY KEY |
| full_name | VARCHAR(150) | NOT NULL |
| email | VARCHAR(255) | NOT NULL, UNIQUE, CHECK contains `@` |
| password_hash | VARCHAR(255) | NOT NULL; bcrypt hash, never plaintext |
| role_id | INT | NOT NULL, FK ROLES ON DELETE RESTRICT |
| department_id | INT | FK DEPARTMENTS ON DELETE SET NULL |
| employment_status | VARCHAR(20) | DEFAULT 'active' |
| account_status | VARCHAR(20) | NOT NULL, DEFAULT 'active', CHECK active/suspended/disabled |
| created_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| last_login_at | TIMESTAMP | NULL allowed |

## DOCUMENT_CATEGORIES
| Column | SQL type | Constraints |
|---|---|---|
| category_id | SERIAL | PRIMARY KEY |
| category_name | VARCHAR(100) | NOT NULL, UNIQUE |
| description | TEXT | NULL allowed |

## DOCUMENTS
| Column | SQL type | Constraints |
|---|---|---|
| document_id | SERIAL | PRIMARY KEY |
| title | VARCHAR(255) | NOT NULL |
| category_id | INT | NOT NULL, FK DOCUMENT_CATEGORIES ON DELETE RESTRICT |
| owner_id | INT | NOT NULL, FK USERS ON DELETE RESTRICT |
| current_version_id | INT | NULL until an approved version exists; FK DOCUMENT_VERSIONS, added after both tables are created |
| mongo_doc_id | VARCHAR(64) | NOT NULL, UNIQUE; MongoDB document reference |
| document_status | VARCHAR(20) | NOT NULL, DEFAULT 'draft', CHECK draft/active/under_review/retired |
| created_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT now(); maintained by trigger |

## DOCUMENT_VERSIONS
| Column | SQL type | Constraints |
|---|---|---|
| version_id | SERIAL | PRIMARY KEY |
| document_id | INT | NOT NULL, FK DOCUMENTS ON DELETE CASCADE |
| version_number | INT | NOT NULL, CHECK > 0, UNIQUE with document_id |
| file_path | VARCHAR(500) | NOT NULL |
| mongo_content_id | VARCHAR(64) | NOT NULL, UNIQUE |
| vector_id | VARCHAR(64) | NULL allowed, UNIQUE; retained because present in the supplied authoritative Mermaid; see ambiguity above |
| checksum | VARCHAR(128) | NOT NULL |
| uploaded_by | INT | NOT NULL, FK USERS ON DELETE RESTRICT |
| approved_by | INT | NULL until approval, FK USERS ON DELETE RESTRICT, CHECK differs from uploaded_by |
| uploaded_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| approved_at | TIMESTAMP | NULL until approval; CHECK nullness matches approved_by |
| effective_date | DATE | NOT NULL |
| expiry_date | DATE | NULL allowed, if present must be after effective_date |
| version_status | VARCHAR(20) | NOT NULL, DEFAULT 'pending_review', CHECK pending_review/approved/superseded/expired |

## DOCUMENT_PERMISSIONS
| Column | SQL type | Constraints |
|---|---|---|
| doc_permission_id | SERIAL | PRIMARY KEY |
| document_id | INT | NOT NULL, FK DOCUMENTS ON DELETE CASCADE |
| role_id | INT | NOT NULL, FK ROLES ON DELETE CASCADE |
| access_level | VARCHAR(20) | NOT NULL, CHECK read/write/approve/admin |
| granted_by | INT | NOT NULL, FK USERS ON DELETE RESTRICT |
| granted_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| revoked_at | TIMESTAMP | NULL; revocation timestamp |
| — | — | UNIQUE(document_id, role_id, access_level) |

## ACCESS_LOGS
| Column | SQL type | Constraints |
|---|---|---|
| log_id | BIGSERIAL | PRIMARY KEY |
| user_id | INT | NOT NULL, FK USERS ON DELETE RESTRICT |
| document_id | INT | NOT NULL, FK DOCUMENTS ON DELETE RESTRICT |
| version_id | INT | FK DOCUMENT_VERSIONS ON DELETE RESTRICT |
| override_id | INT | FK ACCESS_OVERRIDES ON DELETE RESTRICT; NULL except emergency access |
| action | VARCHAR(20) | NOT NULL, CHECK view/download/upload/edit/approve |
| is_break_glass | BOOLEAN | NOT NULL, DEFAULT false; equals whether override_id is non-NULL |
| ip_address | VARCHAR(45) | NULL allowed |
| accessed_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| prev_hash | CHAR(64) | NOT NULL; previous row hash or 64 zero genesis value |
| row_hash | CHAR(64) | NOT NULL, UNIQUE; SHA-256 hash of previous hash and row fields |

The BEFORE INSERT trigger serializes writers with `pg_advisory_xact_lock`, reads the last row hash, and computes the new hash with `pgcrypto.digest`. A BEFORE UPDATE OR DELETE trigger rejects mutation; the runtime role also lacks those grants. The verification function returns the first broken log id (or NULL). Persistent verification history is not stored because its former table is outside this model.

## ACCESS_OVERRIDES
| Column | SQL type | Constraints |
|---|---|---|
| override_id | SERIAL | PRIMARY KEY |
| user_id | INT | NOT NULL, FK USERS ON DELETE RESTRICT; requester |
| document_id | INT | NOT NULL, FK DOCUMENTS ON DELETE RESTRICT |
| justification | TEXT | NOT NULL, CHECK trimmed length >= 20 |
| granted_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| expires_at | TIMESTAMP | NOT NULL, after granted_at and no later than 24 hours after it |
| status | VARCHAR(10) | NOT NULL, DEFAULT 'active', CHECK active/expired/reviewed |
| reviewed_by | INT | FK USERS ON DELETE RESTRICT, NULL while pending; must differ from requester |
| reviewed_at | TIMESTAMP | NULL until reviewed |
| review_outcome | VARCHAR(15) | NULL or justified/unjustified |

## POLICY_ASSIGNMENTS
| Column | SQL type | Constraints |
|---|---|---|
| assignment_id | SERIAL | PRIMARY KEY |
| document_id | INT | NOT NULL, FK DOCUMENTS ON DELETE CASCADE |
| target_role_id | INT | FK ROLES ON DELETE CASCADE; nullable |
| target_department_id | INT | FK DEPARTMENTS ON DELETE CASCADE; nullable |
| assigned_by | INT | NOT NULL, FK USERS ON DELETE RESTRICT |
| assigned_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| due_date | DATE | NOT NULL, not before assigned_at::date |
| — | — | CHECK at least one of target_role_id or target_department_id is non-NULL |

## ACKNOWLEDGMENTS
| Column | SQL type | Constraints |
|---|---|---|
| ack_id | BIGSERIAL | PRIMARY KEY |
| assignment_id | INT | NOT NULL, FK POLICY_ASSIGNMENTS ON DELETE CASCADE |
| user_id | INT | NOT NULL, FK USERS ON DELETE CASCADE |
| version_id | INT | NOT NULL, FK DOCUMENT_VERSIONS ON DELETE RESTRICT |
| acknowledged_at | TIMESTAMP | NOT NULL, DEFAULT now() |
| — | — | UNIQUE(assignment_id, user_id, version_id) |

Only completed acknowledgments are stored. Pending users are derived for the current document version by a LEFT JOIN anti-join. A new approved version therefore requires a new acknowledgment without deleting old acknowledgments.

## Relationships and deletion rules

- One department and one role can each be associated with many users.
- One category and one owner can each be associated with many documents.
- A document has many versions; its nullable current-version pointer refers to one of those versions. The pointer FK is added after version-table creation to resolve the circular reference.
- A document and role can have many permission rows; a user grants them.
- A user, document, and optional version/override are referenced by access-log rows. Logs restrict deletion of referenced users/documents/versions/overrides.
- A document can have many policy assignments; assignments may target a role, department, or both.
- Acknowledgments reference one assignment, user, and exact version.
- An override has one requester, one document, and optionally one different reviewing user; an override may tag many access log rows.

## Database behaviors

Version transitions and maker-checker are database-enforced. Approval updates the current-version pointer and supersedes the previous version transactionally. Expiry scheduling updates past-due approved versions. Break-glass grant, access log insertion, and review are transactional. The access function uses role-based document grants plus an active, unexpired override. Department acknowledgment summaries use joins, anti-joins, GROUP BY and HAVING. Audit integrity uses the hash chain and verification function.
