const functions = require("firebase-functions");
const https = require("https");
const KEY = "YOUR_ANTHROPIC_API_KEY_HERE";
exports.claudeProxy = functions.https.onRequest((req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }
  if (req.method !== "POST") { res.status(405).send("Not Allowed"); return; }
  const body = JSON.stringify(req.body);
  const opts = { hostname: "api.anthropic.com", path: "/v1/messages", method: "POST", headers: { "Content-Type": "application/json", "x-api-key": KEY, "anthropic-version": "2023-06-01", "Content-Length": Buffer.byteLength(body) } };
  const r = https.request(opts, (resp) => { let data = ""; resp.on("data", (chunk) => { data += chunk; }); resp.on("end", () => { res.status(resp.statusCode).set("Content-Type","application/json").send(data); }); });
  r.on("error", (e) => { res.status(500).json({ error: e.message }); });
  r.write(body);
  r.end();
});
