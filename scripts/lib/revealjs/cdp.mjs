import http from "node:http";

export class CdpError extends Error {
  constructor(message, { method = "", code = undefined, data = undefined } = {}) {
    super(message);
    this.name = "CdpError";
    this.method = method;
    this.code = code;
    this.data = data;
  }
}

export class CdpConnection {
  constructor(socket) {
    this.socket = socket;
    this.nextId = 0;
    this.pending = new Map();
    this.eventListeners = new Set();
    socket.addEventListener("message", (event) => this.#message(event));
    socket.addEventListener("error", (event) => this.#rejectPending(`DevTools WebSocket error: ${event.message || "unknown error"}`));
    socket.addEventListener("close", (event) => this.#rejectPending(`DevTools WebSocket closed: code=${event.code || 0} reason=${event.reason || ""}`));
  }

  send(method, params = {}, sessionId = undefined) {
    const id = ++this.nextId;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject, method });
      try {
        this.socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
      } catch (error) {
        this.pending.delete(id);
        reject(error);
      }
    });
  }

  close() {
    this.#rejectPending("DevTools WebSocket closed");
    this.socket.close();
  }

  onEvent(listener) {
    this.eventListeners.add(listener);
    return () => this.eventListeners.delete(listener);
  }

  #message(event) {
    let message;
    try { message = JSON.parse(event.data); } catch { return; }
    if (!message.id) {
      for (const listener of this.eventListeners) listener(message);
      return;
    }
    if (!this.pending.has(message.id)) return;
    const callback = this.pending.get(message.id);
    this.pending.delete(message.id);
    if (message.error) {
      callback.reject(new CdpError(message.error.message || "CDP request failed", {
        method: callback.method,
        code: message.error.code,
        data: message.error.data,
      }));
    } else {
      callback.resolve(message.result);
    }
  }

  #rejectPending(message) {
    if (!this.pending.size) return;
    const error = new Error(message);
    for (const callback of this.pending.values()) callback.reject(error);
    this.pending.clear();
  }
}

export class CdpSession {
  constructor(connection, sessionId) {
    this.connection = connection;
    this.sessionId = sessionId;
  }

  send(method, params = {}) {
    return this.connection.send(method, params, this.sessionId);
  }

  onEvent(listener) {
    return this.connection.onEvent((message) => {
      if (message.sessionId === this.sessionId) listener(message);
    });
  }

  close() {
    this.connection.close();
  }
}

export async function connectWebSocket(url, { WebSocketImpl = globalThis.WebSocket } = {}) {
  if (!WebSocketImpl) throw new Error("This Node runtime does not provide WebSocket");
  const socket = new WebSocketImpl(url);
  await new Promise((resolve, reject) => {
    let settled = false;
    const succeed = () => { if (!settled) { settled = true; resolve(); } };
    const fail = (error) => { if (!settled) { settled = true; reject(error); } };
    socket.addEventListener("open", succeed, { once: true });
    socket.addEventListener("error", (event) => fail(new Error(event.message || "DevTools WebSocket connection failed")), { once: true });
    socket.addEventListener("close", () => fail(new Error("DevTools WebSocket closed before opening")), { once: true });
  });
  return new CdpConnection(socket);
}

export function getJson(port, pathname, { host = "127.0.0.1" } = {}) {
  return new Promise((resolve, reject) => {
    const request = http.get({ host, port, path: pathname }, (response) => {
      let body = "";
      response.setEncoding("utf8");
      response.on("data", (chunk) => { body += chunk; });
      response.on("end", () => {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          reject(new Error(`HTTP ${response.statusCode} for ${pathname}`));
          return;
        }
        try { resolve(JSON.parse(body)); } catch (error) { reject(error); }
      });
    });
    request.on("error", reject);
  });
}

export async function selectOrCreateTarget(port, { targetUrl = "about:blank", host = "127.0.0.1" } = {}) {
  let targets = await getJson(port, "/json/list", { host });
  let page = targets.find((target) => target.type === "page");
  if (page) return page;
  const version = await getJson(port, "/json/version", { host });
  const browser = await connectWebSocket(version.webSocketDebuggerUrl);
  try {
    const created = await browser.send("Target.createTarget", { url: targetUrl });
    for (let attempt = 0; attempt < 40; attempt += 1) {
      targets = await getJson(port, "/json/list", { host });
      page = targets.find((target) => target.id === created.targetId) || targets.find((target) => target.type === "page");
      if (page) return page;
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  } finally {
    browser.close();
  }
  throw new Error("No Chrome page target found");
}

export async function connectToTarget(port, { targetUrl = "about:blank", host = "127.0.0.1" } = {}) {
  const version = await getJson(port, "/json/version", { host });
  const connection = await connectWebSocket(version.webSocketDebuggerUrl);
  let targets = await getJson(port, "/json/list", { host });
  let target = targets.find((item) => item.type === "page");
  if (!target) {
    const created = await connection.send("Target.createTarget", { url: targetUrl });
    for (let attempt = 0; attempt < 40; attempt += 1) {
      targets = await getJson(port, "/json/list", { host });
      target = targets.find((item) => item.id === created.targetId) || targets.find((item) => item.type === "page");
      if (target) break;
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!target) {
    connection.close();
    throw new Error("No Chrome page target found");
  }
  const attached = await connection.send("Target.attachToTarget", { targetId: target.id, flatten: true });
  return { target, connection, cdp: new CdpSession(connection, attached.sessionId) };
}
