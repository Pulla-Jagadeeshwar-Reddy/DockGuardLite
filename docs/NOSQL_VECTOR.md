# MongoDB content storage

MongoDB stores extracted policy text and flexible extraction metadata. PostgreSQL owns users, role-based document grants, document/version state, assignments, acknowledgments, overrides and access logs. Mongo records are never authorization claims.

## Collection: `document_contents`

One record represents one uploaded version's extracted content:

```javascript
{
  _id: "content-uuid",
  mongoDocId: "document-reference",
  documentId: 42,
  versionId: 103,
  category: "Infection Control",
  title: "Standard Precautions",
  fileName: "policy.pdf",
  mimeType: "application/pdf",
  pageCount: 4,
  pages: [{ n: 1, text: "..." }],
  sections: [{ heading: "Hand hygiene", level: 2, pageStart: 1, lineStart: 4 }],
  extracted: { keywords: ["hand", "hygiene"], wordCount: 920, language: "en", tables: [], datesMentioned: [] },
  createdAt: ISODate("2026-11-01T00:00:00Z")
}
```

Nested page, section and extraction fields vary without creating optional relational columns. PostgreSQL stores each version's `mongo_content_id` and remains authoritative for access and lifecycle.

## Indexes and CRUD lifecycle

`database/mongo/indexes.js` creates a unique partial index for linked version ids, plus indexes for document/category, extracted keywords, category and creation time.

- **Create:** ingestion extracts PDF/DOCX text and inserts a content record.
- **Read:** an authorized version request resolves its content id through PostgreSQL, then reads the matching Mongo record.
- **Update:** after PostgreSQL assigns ids, ingestion links the record to its document and version.
- **Delete:** failed SQL writes trigger compensating deletion; an orphan sweeper deletes old unlinked content.
- **Aggregate:** an Admin-only summary groups eligible policy counts, pages and extracted word counts by category and ranks extracted terms. Express obtains eligible current version ids from PostgreSQL before Mongo aggregation.

The aggregation demonstrates `$match`, `$facet`, `$unwind`, `$group`, `$sort` and `$limit`. It returns descriptive summaries, not policy answers.

## Extraction limits

PDF and DOCX text extraction is local. Scanned-image OCR is not supported. Demo policies are fictional.
