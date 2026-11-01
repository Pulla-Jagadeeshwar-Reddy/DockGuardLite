# Queries for DocuGuard Lite

Examples use the 11-table relational model and demonstrate joins, nested/correlated filters, aggregation, window functions and a recursive CTE without adding relations.

## Permission-aware document listing (JOIN and nested filter)

```sql
SELECT d.document_id, d.title, c.category_name, v.version_number, v.version_status
FROM documents d
JOIN document_categories c ON c.category_id = d.category_id
LEFT JOIN document_versions v ON v.version_id = d.current_version_id
WHERE EXISTS (
  SELECT 1 FROM document_permissions p
  JOIN users u ON u.role_id = p.role_id
  WHERE u.user_id = $1 AND u.account_status = 'active'
    AND p.document_id = d.document_id AND p.revoked_at IS NULL
)
ORDER BY d.title;
```

The correlated `EXISTS` checks the authenticated user's role against grants for each candidate document. Emergency access can be unioned into the predicate for document reads.

## Pending acknowledgment anti-join

```sql
SELECT pa.assignment_id, d.title, u.user_id, u.full_name, v.version_number, pa.due_date
FROM policy_assignments pa
JOIN documents d ON d.document_id = pa.document_id
JOIN document_versions v ON v.version_id = d.current_version_id
JOIN users u ON u.account_status = 'active'
  AND (pa.target_role_id IS NULL OR pa.target_role_id = u.role_id)
  AND (pa.target_department_id IS NULL OR pa.target_department_id = u.department_id)
LEFT JOIN acknowledgments a ON a.assignment_id = pa.assignment_id
  AND a.user_id = u.user_id AND a.version_id = v.version_id
WHERE a.ack_id IS NULL
  AND d.document_status = 'active' AND v.version_status = 'approved'
  AND (v.expiry_date IS NULL OR v.expiry_date >= CURRENT_DATE);
```

The anti-join derives pending users. The version id ensures acknowledging an older version does not complete the current assignment.

## Department completion with GROUP BY and HAVING

```sql
SELECT department_name,
       count(*) AS eligible,
       count(*) FILTER (WHERE acknowledged) AS completed,
       round(100.0 * count(*) FILTER (WHERE acknowledged) / NULLIF(count(*), 0), 2) AS completion_percent
FROM v_ack_compliance_by_department
GROUP BY department_name
HAVING count(*) FILTER (WHERE NOT acknowledged) > 0
ORDER BY completion_percent;
```

This returns departments with at least one outstanding assignment.

## Correlated expiry query

```sql
SELECT d.document_id, d.title, v.expiry_date
FROM documents d
JOIN document_versions v ON v.version_id = d.current_version_id
WHERE v.version_status = 'approved'
  AND v.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
  AND EXISTS (
    SELECT 1 FROM document_permissions p
    JOIN users u ON u.role_id = p.role_id
    WHERE u.user_id = $1 AND p.document_id = d.document_id AND p.revoked_at IS NULL
  );
```

The inner query makes the expiry list specific to a user's permitted documents.

## Recursive version history

```sql
WITH RECURSIVE lineage(version_id, document_id, version_number, depth, path) AS (
  SELECT version_id, document_id, version_number, 1, ARRAY[version_id]
  FROM document_versions WHERE version_id = $1
  UNION ALL
  SELECT prior.version_id, prior.document_id, prior.version_number,
         current.depth + 1, current.path || prior.version_id
  FROM lineage current
  JOIN document_versions prior
    ON prior.document_id = current.document_id
   AND prior.version_number = current.version_number - 1
  WHERE NOT prior.version_id = ANY(current.path)
)
SELECT version_id, version_number, depth
FROM lineage ORDER BY version_number;
```

This walks a document's numbered versions using the existing document/version relationship. It is a proposed replacement for recursive-query coursework; it does not add a table.

## Window function over access history

```sql
SELECT user_id, log_id, accessed_at,
       lag(accessed_at) OVER (PARTITION BY user_id ORDER BY log_id) AS previous_access
FROM access_logs
ORDER BY user_id, log_id;
```

The window function compares each event with the prior event for that user without collapsing the rows.

## MongoDB content aggregation

```javascript
[
  { $facet: {
    categories: [
      { $group: { _id: "$category", policies: { $sum: 1 }, pages: { $sum: "$pageCount" }, words: { $sum: "$extracted.wordCount" } } },
      { $sort: { policies: -1, _id: 1 } }
    ],
    frequentTerms: [
      { $unwind: "$extracted.keywords" },
      { $group: { _id: "$extracted.keywords", uses: { $sum: 1 } } },
      { $sort: { uses: -1, _id: 1 } }, { $limit: 10 }
    ]
  } }
]
```

The API should first obtain accessible current version ids from PostgreSQL and filter the Mongo pipeline by them. This keeps authorization in the relational system.
