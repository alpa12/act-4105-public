import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const MIME_TYPES = Object.freeze({
  ".html": "text/html; charset=utf-8",
  ".htm": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".webp": "image/webp",
  ".ico": "image/x-icon",
});

function normalizeRequestPath(requestPath) {
  const rawPath = requestPath instanceof URL
    ? requestPath.pathname
    : String(requestPath).split(/[?#]/, 1)[0];
  try {
    return decodeURIComponent(rawPath);
  } catch {
    throw new Error("Invalid URL encoding");
  }
}

export function resolveSafePath(root, requestPath) {
  const rootPath = path.resolve(root);
  const pathname = normalizeRequestPath(requestPath);
  const relativePath = pathname === "/" ? "index.html" : pathname.replace(/^\/+/, "");
  const resolved = path.resolve(rootPath, relativePath);
  if (resolved !== rootPath && !resolved.startsWith(`${rootPath}${path.sep}`)) {
    return null;
  }
  return resolved;
}

export function injectPreflight(html, preflight) {
  if (!preflight || html.includes("act-print-preflight")) {
    return html;
  }
  if (html.includes("</head>")) {
    return html.replace("</head>", `${preflight}\n</head>`);
  }
  return `${preflight}${html}`;
}

export function servedUrl(baseUrl, pathname, search = "") {
  const url = new URL(baseUrl);
  url.pathname = `/${String(pathname).replace(/^\/+/, "")}`;
  url.search = search;
  return url.toString();
}

export async function createStaticServer({
  root,
  preflightPath = "",
  injectPrintPreflight = false,
  host = "127.0.0.1",
} = {}) {
  if (!root) throw new Error("A server root is required");
  const rootPath = path.resolve(root);
  const preflight = injectPrintPreflight && preflightPath
    ? await fs.readFile(preflightPath, "utf8")
    : "";

  const server = http.createServer(async (request, response) => {
    let filePath;
    try {
      filePath = resolveSafePath(rootPath, request.url || "/");
    } catch {
      response.writeHead(400);
      response.end();
      return;
    }
    if (!filePath) {
      response.writeHead(403);
      response.end();
      return;
    }
    try {
      let data = await fs.readFile(filePath);
      const extension = path.extname(filePath).toLowerCase();
      if (preflight && extension === ".html") {
        data = Buffer.from(injectPreflight(data.toString("utf8"), preflight), "utf8");
      }
      response.writeHead(200, {
        "content-type": MIME_TYPES[extension] || "application/octet-stream",
        "cache-control": "no-store",
      });
      if (request.method !== "HEAD") response.end(data);
      else response.end();
    } catch (error) {
      response.writeHead(error.code === "ENOENT" ? 404 : 500);
      response.end();
    }
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, host, resolve);
  });
  const address = server.address();
  const port = typeof address === "object" && address ? address.port : null;
  if (!port) throw new Error("Static server did not expose a port");

  return {
    server,
    root: rootPath,
    host,
    port,
    baseUrl: `http://${host}:${port}/`,
    close: () => new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve())),
  };
}

function parseArguments(argv) {
  const options = { injectPrintPreflight: false };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--root") options.root = argv[++index];
    else if (argument === "--preflight") options.preflightPath = argv[++index];
    else if (argument === "--inject-preflight") options.injectPrintPreflight = true;
    else if (argument === "--help" || argument === "-h") options.help = true;
    else throw new Error(`Unknown option: ${argument}`);
  }
  return options;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    const options = parseArguments(process.argv.slice(2));
    if (options.help || !options.root) {
      console.log("Usage: static-server.mjs --root DIR [--preflight FILE --inject-preflight]");
      process.exit(options.help ? 0 : 2);
    }
    const server = await createStaticServer(options);
    console.log(`PORT=${server.port}`);
    const close = async () => {
      try { await server.close(); } finally { process.exit(0); }
    };
    process.once("SIGINT", close);
    process.once("SIGTERM", close);
  } catch (error) {
    console.error(error.stack || error);
    process.exit(1);
  }
}
