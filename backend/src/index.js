import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const app = express();
const PORT = process.env.PORT || 8000;

// Determine current deployment color
const DEPLOY_COLOR = process.env.DEPLOY_COLOR || "unknown";

// Basic logging
console.log(`🚀 Starting EdgeWave backend (${DEPLOY_COLOR}) on port ${PORT}`);

// Example health endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    version: DEPLOY_COLOR,
    message: `${DEPLOY_COLOR.toUpperCase()} DEPLOYMENT ACTIVE`
  });
});

// Optional root route (for manual testing)
app.get("/", (req, res) => {
  res.send(`<h3>${DEPLOY_COLOR === "green" ? "🟢 GREEN" : "🔵 BLUE"} BACKEND ACTIVE</h3>`);
});

// If serving static frontend (optional)
const __dirname = path.dirname(fileURLToPath(import.meta.url));
app.use(express.static(path.join(__dirname, "public")));

app.listen(PORT, () =>
  console.log(`✅ EdgeWave backend running on port ${PORT} (${DEPLOY_COLOR})`)
);
