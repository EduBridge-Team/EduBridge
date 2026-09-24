import { createServer } from "node:http";
import { request as httpsRequest } from "node:https";
import { createReadStream, existsSync, statSync } from "node:fs";
import { extname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../edubridge-web/dist/", import.meta.url));
const port = Number(process.env.PORT || 8080);
const apiOrigin = new URL(process.env.API_ORIGIN || "https://api.edubridge.win");

if (apiOrigin.protocol !== "https:") {
  throw new Error("API_ORIGIN must use https");
}

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

  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.setHeader("X-Frame-Options", "SAMEORIGIN");

  // Keep browser requests same-origin. This avoids CORS/TLS edge cases between
  // edubridge.win and api.edubridge.win while preserving the public API domain.
  if (requestUrl === "/api" || requestUrl.startsWith("/api/")) {
    proxyApi(req, res);
    return;
  }

  if (!["GET", "HEAD"].includes(req.method || "GET")) {
    res.statusCode = 405;
    res.setHeader("Allow", "GET, HEAD");
    res.end("Method Not Allowed");
    return;
  }

  let rawPath;
  try {
    const parsed = new URL(requestUrl, "http://localhost");
    rawPath = decodeURIComponent(parsed.pathname);
  } catch {
    res.statusCode = 400;
    res.end("Bad Request");
    return;
  }

  const requestedPath = resolve(root, `.${rawPath}`);
  const relativePath = relative(root, requestedPath);
  const escapedRoot = relativePath === ".." || relativePath.startsWith("../");

  if (escapedRoot) {
    res.statusCode = 403;
    res.end("Forbidden");
    return;
  }

  let filePath = rawPath === "/" ? resolve(root, "index.html") : requestedPath;
  let spaFallback = false;

  if (!existsSync(filePath) || !statSync(filePath).isFile()) {
    filePath = resolve(root, "index.html");
    spaFallback = true;
  }

  const isHtml = filePath.endsWith("index.html");
  const isHashedAsset = rawPath.startsWith("/assets/") && !spaFallback;

  res.setHeader("Content-Type", mime[extname(filePath).toLowerCase()] || "application/octet-stream");
  res.setHeader(
    "Cache-Control",
    isHtml || spaFallback
      ? "no-cache"
      : isHashedAsset
        ? "public, max-age=31536000, immutable"
        : "public, max-age=3600",
  );

  if (req.method === "HEAD") {
    res.end();
    return;
  }

  const stream = createReadStream(filePath);
  stream.on("error", (error) => {
    console.error("EduBridge static file error:", error);
    if (!res.headersSent) res.statusCode = 500;
    res.end();
  });
  stream.pipe(res);
}).listen(port, "0.0.0.0", () => {
  console.log(`EduBridge Web listening on 0.0.0.0:${port}`);
  console.log(`EduBridge API proxy: /api -> ${apiOrigin.origin}`);
});
