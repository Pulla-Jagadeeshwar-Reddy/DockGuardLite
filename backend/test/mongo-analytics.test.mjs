import assert from "node:assert/strict";
import { afterAll, test } from "@jest/globals";
import request from "supertest";
import { app } from "../dist/app.js";
import { mongoClient, pgPool } from "../dist/config/databases.js";

test("Admin content summary aggregates seeded MongoDB content; other roles are denied", async () => {
  const admin = request.agent(app);
  const nurse = request.agent(app);
  assert.equal((await admin.post("/api/auth/login").send({ email: "admin1@docuguard.local", password: "DG-Demo-Admin-01!" })).status, 200);
  assert.equal((await nurse.post("/api/auth/login").send({ email: "nurse1@docuguard.local", password: "DG-Demo-Nurse-01!" })).status, 200);
  const response = await admin.get("/api/analytics/keywords");
  assert.equal(response.status, 200);
  assert.ok(Array.isArray(response.body.topKeywords));
  assert.ok(Array.isArray(response.body.categories));
  assert.ok(Array.isArray(response.body.longestDocuments));
  assert.ok(response.body.categories.length > 0);
  assert.ok(response.body.topKeywords.length > 0);
  assert.equal((await nurse.get("/api/analytics/keywords")).status, 403);

  const mongoDocs = await mongoClient.db(process.env.MONGO_DB).collection("document_contents").countDocuments({ versionId: { $type: "number" } });
  const sqlVersions = await pgPool.query(
    `SELECT count(*)::int AS count FROM documents d JOIN document_versions v ON v.version_id=d.current_version_id
     WHERE d.document_status='active' AND v.version_status='approved' AND (v.expiry_date IS NULL OR v.expiry_date>=CURRENT_DATE)`
  );
  assert.ok(mongoDocs >= sqlVersions.rows[0].count);
});

afterAll(async () => { await pgPool.end(); await mongoClient.close(); });
