import { MongoClient } from 'mongodb';
import { config } from 'dotenv';
import { fileURLToPath } from 'node:url';
config({ path: fileURLToPath(new URL('../../.env', import.meta.url)) });
const uri = process.env.MONGO_URI;
const dbName = process.env.MONGO_DB;
if (!uri || !dbName) throw new Error('MONGO_URI and MONGO_DB must be set in the repository .env file.');
const client = new MongoClient(uri, { serverSelectionTimeoutMS: 5000 });
try {
  await client.connect();
  const db = client.db(dbName);
  const exists = await db.listCollections({ name: 'document_contents' }, { nameOnly: true }).hasNext();
  if (!exists) await db.createCollection('document_contents');
  const contents = db.collection('document_contents');
  const indexes = await contents.listIndexes().toArray();
  const old = indexes.find(index => index.name === 'uq_document_contents_version');
  if (old && !old.partialFilterExpression?.versionId?.$type) await contents.dropIndex('uq_document_contents_version');
  await contents.createIndex({ versionId: 1 }, { name: 'uq_document_contents_version', unique: true, partialFilterExpression: { versionId: { $type: 'number' } } });
  await contents.createIndexes([
    { key: { documentId: 1, category: 1 }, name: 'idx_document_contents_document_category' },
    { key: { 'extracted.keywords': 1 }, name: 'idx_document_contents_keywords' },
    { key: { category: 1 }, name: 'idx_document_contents_category' },
    { key: { createdAt: -1 }, name: 'idx_document_contents_created_at' }
  ]);
  console.log(`MongoDB content indexes ready for database "${dbName}".`);
} finally { await client.close(); }
