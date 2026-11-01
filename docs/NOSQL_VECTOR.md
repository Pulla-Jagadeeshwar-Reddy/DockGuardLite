# MongoDB Content Store

The lite application uses MongoDB as a document-content store alongside PostgreSQL. PostgreSQL owns users, permissions, document/version state, acknowledgments, overrides and audit logs. MongoDB stores extracted document content and flexible extraction metadata. Mongo records are references to relational document/version ids; they are never authorization claims.

## Collection: `document_contents`

One record represents the extracted content of one uploaded version. Example shape:

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
  extracted: {
    keywords: ["hand hygiene", "clinical staff"],
    wordCount: 920,
    language: "en",
    tables: [],
    datesMentioned: []
  },
  createdAt: ISODate("2026-11-01T00:00:00Z")
}
```

Nested page/section/extraction fields can vary without creating a large set of optional relational columns. PostgreSQL stores the version's `mongo_content_id` and remains authoritative for permissions and lifecycle.

## Indexes and CRUD lifecycle

`database/mongo/indexes.js` creates a unique partial index for linked version ids plus indexes for document/category, extracted keywords, and creation time.

- **Create:** ingestion extracts PDF/DOCX text and inserts a content record.
- **Read:** a permitted document/version request resolves its Mongo content id through PostgreSQL, then reads the matching content record.
- **Update:** after PostgreSQL assigns ids, ingestion links the Mongo record to document and version ids.
- **Delete:** failed relational writes trigger compensating deletion; an orphan sweep deletes old unlinked content.
- **Aggregate:** an Admin-only summary may group policy counts, pages and extracted word counts by category and show frequent extracted terms. The endpoint must derive eligible version ids from PostgreSQL first.

## Document extraction limits

PDF and DOCX text extraction is local. Scanned-image OCR is not supported. Demo policy content is fictional. MongoDB content supports browsing and summaries; it does not generate policy answers.


