import assert from "node:assert/strict";
import http from "node:http";
import { mkdtemp, mkdir, readFile, writeFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { CdpConnection, CdpError } from "../cdp.mjs";
import {
  h1H2OutlinePreparationExpression,
  headingUnderlinePreparationExpression,
  pdfPageViewportExpression,
  pdfPrintOptions,
} from "../pdf.mjs";
import { enumerateRevealSlides } from "../reveal.mjs";
import { createStaticServer, injectPreflight, MIME_TYPES, resolveSafePath, servedUrl } from "../static-server.mjs";

test("resolveSafePath blocks directory traversal", () => {
  const root = path.join(os.tmpdir(), "reveal-root");
  assert.equal(resolveSafePath(root, "/../secret.txt"), null);
  assert.equal(resolveSafePath(root, "/%2e%2e/secret.txt"), null);
  assert.equal(resolveSafePath(root, "/chapitre/diapos.html"), path.join(root, "chapitre", "diapos.html"));
});

test("static server serves required MIME types and injects preflight once", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "reveal-server-"));
  const preflightPath = path.join(root, "preflight.html");
  await mkdir(path.join(root, "assets"));
  await writeFile(path.join(root, "index.html"), "<html><head></head><body></body></html>");
  await writeFile(path.join(root, "assets", "font.woff2"), "font");
  await writeFile(preflightPath, '<script data-act="act-print-preflight">window.x=1</script>');
  const server = await createStaticServer({ root, preflightPath, injectPrintPreflight: true });
  try {
    const html = await fetch(`${server.baseUrl}index.html`).then((response) => response.text());
    assert.equal(html.match(/act-print-preflight/g).length, 1);
    const second = injectPreflight(html, '<script data-act="act-print-preflight">window.x=1</script>');
    assert.equal(second.match(/act-print-preflight/g).length, 1);
    const font = await fetch(`${server.baseUrl}assets/font.woff2`);
    assert.equal(font.headers.get("content-type"), MIME_TYPES[".woff2"]);
    const traversalStatus = await new Promise((resolve, reject) => {
      const request = http.get({ hostname: "127.0.0.1", port: server.port, path: "/%2e%2e/preflight.html" }, (response) => {
        response.resume();
        response.on("end", () => resolve(response.statusCode));
      });
      request.on("error", reject);
    });
    assert.equal(traversalStatus, 403);
  } finally {
    await server.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("servedUrl resolves chapter paths", () => {
  assert.equal(servedUrl("http://127.0.0.1:1234/", "chapitres/01/diapos.html", "print-pdf"), "http://127.0.0.1:1234/chapitres/01/diapos.html?print-pdf");
});

class FakeSocket extends EventTarget {
  send(payload) {
    const message = JSON.parse(payload);
    queueMicrotask(() => {
      const response = message.method === "Runtime.fail"
        ? { id: message.id, error: { code: -32000, message: "expected failure" } }
        : { id: message.id, result: { method: message.method } };
      this.dispatchEvent(new MessageEvent("message", { data: JSON.stringify(response) }));
    });
  }
  close() {}
}

test("CDP call queue resolves and rejects calls", async () => {
  const cdp = new CdpConnection(new FakeSocket());
  const [first, second] = await Promise.all([cdp.send("Runtime.evaluate"), cdp.send("Page.enable")]);
  assert.equal(first.method, "Runtime.evaluate");
  assert.equal(second.method, "Page.enable");
  await assert.rejects(cdp.send("Runtime.fail"), (error) => error instanceof CdpError && error.code === -32000);
});

test("Reveal traversal includes vertical slides and fragment states", () => {
  assert.deepEqual(enumerateRevealSlides([
    { fragmentCount: 0 },
    { verticalSlides: [{ fragmentCount: 1 }, { fragmentCount: 2 }] },
  ]), [
    { h: 0, v: 0, f: null },
    { h: 1, v: 0, f: null },
    { h: 1, v: 0, f: 0 },
    { h: 1, v: 1, f: null },
    { h: 1, v: 1, f: 0 },
    { h: 1, v: 1, f: 1 },
  ]);
});

test("PDF outline options are opt-in and target H1/H2 only", () => {
  assert.equal(pdfPrintOptions().generateDocumentOutline, undefined);
  assert.equal(pdfPrintOptions().generateTaggedPDF, undefined);
  const outlineOptions = pdfPrintOptions({ outlineH1H2: true });
  assert.equal(outlineOptions.generateDocumentOutline, true);
  assert.equal(outlineOptions.generateTaggedPDF, true);

  const preparation = h1H2OutlinePreparationExpression();
  assert.match(preparation, /const softBreak/);
  assert.match(preparation, /lineBreak\.after/);
  assert.match(preparation, /\.pdf-page section\.slide/);
  assert.match(preparation, /h3, h4, h5, h6/);
  assert.match(preparation, /label === previousH2/);
});

test("PDF export explicitly remeasures heading underlines after print pages are ready", async () => {
  const preparation = headingUnderlinePreparationExpression();
  assert.match(preparation, /window\.__actMeasureHeadingUnderlines/);
  assert.match(preparation, /Promise\.resolve\(measure\(\)\)/);
  let calls = 0;
  const result = await Function("window", `return ${preparation}`)({
    __actMeasureHeadingUnderlines: async () => { calls += 1; },
  });
  assert.equal(calls, 1);
  assert.deepEqual(result, { measured: true });
});

test("PDF export derives a viewport from the rendered print page", () => {
  const expression = pdfPageViewportExpression();
  const document = {
    querySelector: (selector) => selector === ".pdf-page"
      ? { getBoundingClientRect: () => ({ width: 1154.2, height: 769.1 }) }
      : null,
  };
  assert.deepEqual(Function("document", `return ${expression}`)(document), {
    width: 1155,
    height: 770,
  });
  assert.equal(Function("document", `return ${expression}`)({ querySelector: () => null }), null);
});

test("heading underline measurement uses text ranges instead of the full heading box", async () => {
  const include = await readFile(new URL("../../../../site/includes/revealjs-heading-underlines.html", import.meta.url), "utf8");
  assert.match(include, /document\.createTreeWalker\(heading, NodeFilter\.SHOW_TEXT\)/);
  assert.match(include, /range\.selectNodeContents\(node\)/);
  assert.doesNotMatch(include, /range\.selectNodeContents\(heading\)/);
});
