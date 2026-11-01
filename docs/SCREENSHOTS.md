# Screenshot Capture Checklist

Status: all screenshots below remain for the student team to capture from the running Lite application. None are included or fabricated. Use synthetic data only; keep credentials, .env contents and private uploaded files out of images.

| # | Page / state | How to reach it |
|---:|---|---|
| 1 | Login with a validation error | /login; submit empty or invalid values. |
| 2 | Admin overview: status, expiry, activity, acknowledgments, common terms | Sign in as admin1@docuguard.local; Overview. |
| 3 | Admin document list | Admin; Documents. |
| 4 | Doctor or Nurse list and role-aware navigation | doctor1@docuguard.local or nurse1@docuguard.local; Documents. |
| 5 | Upload form with a selected synthetic PDF or DOCX | Doctor; Documents; upload; /documents/new. |
| 6 | Document detail with pending version | Open uploaded document before approval. |
| 7 | Approved version and version history | Different Admin approves the version. |
| 8 | My Policies before and after acknowledging | nurse2@docuguard.local; My Policies. |
| 9 | Admin acknowledgment table and department chart | Admin; Acknowledgments. |
| 10 | Emergency form with required justification and duration | Doctor or Nurse; Emergency access. |
| 11 | Admin emergency review queue with pending request | Admin; Emergency reviews. |
| 12 | Audit filters, events and intact verification | Admin; Audit log; click Verify integrity. |
| 13 | User administration with roles and departments | Admin; User administration. |
| 14 | Mongo-backed common terms on dashboard | Admin; Overview. |
| 15 | Role-based denial or inaccessible-document response without sensitive data | Use a role without a grant; capture visible denial state. |

SQL terminal and hash-tampering screenshots are optional if requested by the instructor. Never show passwords, JWT cookies, environment values or real patient information.
