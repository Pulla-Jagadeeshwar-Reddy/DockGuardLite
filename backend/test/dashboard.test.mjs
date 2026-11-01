import assert from "node:assert/strict";
import { afterAll, test } from "@jest/globals";
import request from "supertest";
import { app } from "../dist/app.js";
import { mongoClient, pgPool } from "../dist/config/databases.js";

const admin = request.agent(app);
const nurse = request.agent(app);

test("dashboard requires login and returns the retained live summaries", async () => {
  assert.equal((await request(app).get("/api/dashboard")).status, 401);
  assert.equal((await admin.post("/api/auth/login").send({ email: "admin1@docuguard.local", password: "DG-Demo-Admin-01!" })).status, 200);
  assert.equal((await nurse.post("/api/auth/login").send({ email: "nurse1@docuguard.local", password: "DG-Demo-Nurse-01!" })).status, 200);
  const adminDashboard = await admin.get("/api/dashboard");
  assert.equal(adminDashboard.status, 200);
  assert.ok(Array.isArray(adminDashboard.body.documentStatuses));
  assert.ok(Array.isArray(adminDashboard.body.expiringSoon));
  assert.ok(Array.isArray(adminDashboard.body.accessActivity));
  const nurseDashboard = await nurse.get("/api/dashboard");
  assert.equal(nurseDashboard.status, 200);
  assert.ok(Array.isArray(nurseDashboard.body.expiringSoon));
});

afterAll(async () => { await pgPool.end(); await mongoClient.close(); });
