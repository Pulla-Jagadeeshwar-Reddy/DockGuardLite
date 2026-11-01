import assert from "node:assert/strict";
import { afterAll, test } from "@jest/globals";
import request from "supertest";
import { app } from "../dist/app.js";
import { mongoClient, pgPool } from "../dist/config/databases.js";

test("audit verification returns a result and persists no verification history", async () => {
  const admin = request.agent(app);
  const nurse = request.agent(app);
  assert.equal((await nurse.post("/api/auth/login").send({ email: "nurse1@docuguard.local", password: "DG-Demo-Nurse-01!" })).status, 200);
  assert.equal((await nurse.post("/api/audit/verify")).status, 403);
  assert.equal((await admin.post("/api/auth/login").send({ email: "admin1@docuguard.local", password: "DG-Demo-Admin-01!" })).status, 200);
  const historyTables = await pgPool.query("SELECT count(*)::int AS count FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE 'audit%check%'");
  assert.equal(historyTables.rows[0].count, 0);

  const result = await admin.post("/api/audit/verify");
  assert.equal(result.status, 200);
  assert.equal(result.body.check.result, "intact");
  assert.equal(result.body.check.firstBrokenLogId, null);
  assert.ok(Number(result.body.check.rowsVerified) >= 0);
  assert.equal(typeof result.body.check.verifiedAt, "string");
  assert.equal("id" in result.body.check, false);

  const after = await pgPool.query("SELECT count(*)::int AS count FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE 'audit%check%'");
  assert.equal(after.rows[0].count, 0);
});

afterAll(async () => { await pgPool.end(); await mongoClient.close(); });
