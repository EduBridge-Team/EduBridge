import { createServer } from "node:http";
import { request as httpsRequest } from "node:https";
import { createReadStream, existsSync, statSync } from "node:fs";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../edubridge-web/dist/", import.meta.url));
const port = Number(process.env.PORT || 8080);
const apiOrigin = new URL(process.env.TAQAT_API_ORIGIN || "https://api.edubridge.win");

const mime = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

const hopByHopHeaders = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

function proxyApi(req, res) {
  const upstream = httpsRequest(
    {
      protocol: apiOrigin.protocol,
      hostname: apiOrigin.hostname,
      port: apiOrigin.port || 443,
      method: req.method,
      path: req.url,
      headers: {
        ...req.headers,
        host: apiOrigin.host,
        "x-forwarded-host": req.headers.host || "",
        "x-forwarded-proto": "https",
      },
    },
    (upstreamRes) => {
      res.statusCode = upstreamRes.statusCode || 502;
      for (const [name, value] of Object.entries(upstreamRes.headers)) {
        if (!hopByHopHeaders.has(name.toLowerCase()) && value !== undefined) {
          res.setHeader(name, value);
        }
      }
      upstreamRes.pipe(res);
    },
  );

  upstream.on("error", (error) => {
    console.error("EduBridge API proxy error:", error);
    if (!res.headersSent) {
      res.statusCode = 502;
      res.setHeader("Content-Type", "application/json; charset=utf-8");
    }
    res.end(JSON.stringify({ error: "تعذّر الاتصال بخادم EduBridge API" }));
  });

  req.pipe(upstream);
}

createServer((req, res) => {
  const requestUrl = req.url || "/";

  // Keep browser requests same-origin. This avoids CORS/TLS edge cases between
  // edubridge.win and api.edubridge.win while preserving the public API domain.
  if (requestUrl === "/api" || requestUrl.startsWith("/api/")) {
    proxyApi(req, res);
    return;
  }

  const rawPath = decodeURIComponent(requestUrl.split("?")[0]);
  const safePath = normalize(rawPath).replace(/^([.][.][/\\])+/, "");
  let filePath = join(root, safePath === "/" ? "index.html" : safePath);

  if (!existsSync(filePath) || !statSync(filePath).isFile()) {
    filePath = join(root, "index.html");
  }

  res.setHeader("Content-Type", mime[extname(filePath).toLowerCase()] || "application/octet-stream");
  res.setHeader("Cache-Control", filePath.endsWith("index.html") ? "no-cache" : "public, max-age=31536000, immutable");
  createReadStream(filePath).pipe(res);
}).listen(port, "0.0.0.0", () => {
  console.log(`EduBridge Web listening on 0.0.0.0:${port}`);
  console.log(`EduBridge API proxy: /api -> ${apiOrigin.origin}`);
});
