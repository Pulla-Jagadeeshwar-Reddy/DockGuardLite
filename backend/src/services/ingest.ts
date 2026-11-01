import { randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { basename, extname } from "node:path";
import mammoth from "mammoth";
import { getDocument } from "pdfjs-dist/legacy/build/pdf.mjs";
import { mongoClient, pgPool } from "../config/databases.js";
import { env } from "../config/env.js";

export type IngestMetadata = { documentId: number | null; mongoDocId?: string; title: string; category: string; fileName: string; mimeType: string };
export type IngestResult = { mongoDocId: string; mongoContentId: string };
type MongoContentDocument = { _id: string; mongoDocId: string; versionId: number | null; documentId: number | null; createdAt?: Date; [key: string]: unknown };

function keywords(text: string): string[] {
  const stop = new Set(["about", "after", "also", "been", "being", "each", "from", "have", "into", "more", "must", "only", "other", "should", "that", "their", "there", "these", "they", "this", "through", "under", "using", "when", "where", "which", "with", "would", "your", "shall", "will", "staff", "policy", "document"]);
  const counts = new Map<string, number>();
  for (const token of text.toLowerCase().match(/[a-z][a-z0-9-]{2,}/g) ?? []) if (!stop.has(token)) counts.set(token, (counts.get(token) ?? 0) + 1);
  return [...counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])).slice(0, 30).map(([word]) => word);
}
async function extractText(path: string): Promise<{ text: string; pages: Array<{ n: number; text: string }> }> {
  const extension = extname(path).toLowerCase();
  if (extension === ".docx") {
    const text = (await mammoth.extractRawText({ path })).value.trim();
    if (!text) throw new Error("The DOCX file contains no extractable text");
    return { text, pages: [{ n: 1, text }] };
  }
  if (extension !== ".pdf") throw new Error("Only PDF and DOCX ingestion is supported");
  const pdf = await getDocument({ data: new Uint8Array(await readFile(path)), useSystemFonts: true }).promise;
  const pages: Array<{ n: number; text: string }> = [];
  for (let n = 1; n <= pdf.numPages; n += 1) {
    const content = await (await pdf.getPage(n)).getTextContent();
    pages.push({ n, text: content.items.map(item => "str" in item ? item.str : "").join(" ").replace(/\s+/g, " ").trim() });
  }
  const text = pages.map(page => page.text).filter(Boolean).join("\n\n");
  if (!text) throw new Error("The PDF contains no extractable text; scanned-image OCR is not supported");
  return { text, pages };
}
function parseSections(text: string) {
  return text.split(/\r?\n/).flatMap((line, index) => {
    const match = line.match(/^\s*(#{1,6})\s+(.+)$/);
    return match ? [{ heading: match[2].trim(), level: match[1].length, lineStart: index + 1 }] : [];
  });
}
export async function ingestFile(path: string, meta: IngestMetadata): Promise<IngestResult> {
  const { text, pages } = await extractText(path);
  const mongoDocId = meta.mongoDocId ?? randomUUID();
  const mongoContentId = randomUUID();
  await mongoClient.connect();
  const collection = mongoClient.db(env.mongoDb).collection<MongoContentDocument>("document_contents");
  try {
    await collection.insertOne({
      _id: mongoContentId, mongoDocId, documentId: meta.documentId, versionId: null,
      category: meta.category, title: meta.title, fileName: basename(meta.fileName), mimeType: meta.mimeType,
      pageCount: pages.length, pages, sections: parseSections(text).map(section => ({ ...section, pageStart: 1 })),
      extracted: { keywords: keywords(text), wordCount: text.split(/\s+/).filter(Boolean).length, language: "en", tables: [], datesMentioned: [] }, createdAt: new Date()
    });
    return { mongoDocId, mongoContentId };
  } catch (error) { await deleteIngested(mongoContentId).catch(() => undefined); throw error; }
}
/** Link content to SQL ids before commit so a failed transaction can compensate in MongoDB. */
export async function linkIngested(mongoContentId: string, mongoDocId: string, documentId: number, versionId: number): Promise<void> {
  await mongoClient.connect();
  const updated = await mongoClient.db(env.mongoDb).collection<MongoContentDocument>("document_contents").updateOne({ _id: mongoContentId }, { $set: { mongoDocId, documentId, versionId } });
  if (updated.matchedCount !== 1) throw new Error("Ingested Mongo content disappeared before it could be linked");
}
export async function deleteIngested(mongoContentId: string): Promise<void> {
  await mongoClient.connect();
  await mongoClient.db(env.mongoDb).collection<MongoContentDocument>("document_contents").deleteOne({ _id: mongoContentId });
}
/** Remove content left behind if its compensating delete failed after SQL rollback. */
export async function sweepOrphanedIngestions(): Promise<number> {
  await mongoClient.connect();
  const contents = mongoClient.db(env.mongoDb).collection<MongoContentDocument>("document_contents");
  const candidates = await contents.find({ createdAt: { $lt: new Date(Date.now() - 60 * 60 * 1000) } }, { projection: { _id: 1 } }).toArray();
  if (!candidates.length) return 0;
  const ids = candidates.map(row => row._id);
  const linked = await pgPool.query("SELECT mongo_content_id FROM document_versions WHERE mongo_content_id = ANY($1::varchar[])", [ids]);
  const existing = new Set<string>(linked.rows.map(row => String(row.mongo_content_id)));
  const orphanIds = ids.filter(id => !existing.has(id));
  if (!orphanIds.length) return 0;
  return (await contents.deleteMany({ _id: { $in: orphanIds } })).deletedCount;
}
export function scheduleOrphanedIngestionSweep(): void {
  const run = () => void sweepOrphanedIngestions().then(count => { if (count) console.info(`DocuGuard orphan sweep removed ${count} unlinked Mongo content record(s)`); }).catch(() => console.warn("DocuGuard Mongo orphan sweep failed; it will retry later"));
  setTimeout(run, 60 * 60 * 1000).unref();
  setInterval(run, 6 * 60 * 60 * 1000).unref();
}
