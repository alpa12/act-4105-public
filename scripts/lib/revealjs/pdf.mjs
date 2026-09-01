import fs from "node:fs/promises";
import { evaluate, navigate, waitForReveal } from "./reveal.mjs";

export function pdfPrintOptions({ outlineH1H2 = false } = {}) {
  return {
    landscape: true,
    displayHeaderFooter: false,
    printBackground: true,
    preferCSSPageSize: true,
    marginTop: 0,
    marginRight: 0,
    marginBottom: 0,
    marginLeft: 0,
    transferMode: "ReturnAsStream",
    ...(outlineH1H2 ? {
      generateTaggedPDF: true,
      generateDocumentOutline: true,
    } : {}),
  };
}

export function h1H2OutlinePreparationExpression() {
  return `(() => {
    const text = (element) => element.textContent.replace(/\\s+/g, " ").trim();
    const softBreak = "\u200B";
    let previousH2 = null;
    let headings = 0;
    let duplicates = 0;

    document.querySelectorAll(".pdf-page h1, .pdf-page h2").forEach((heading) => {
      if (heading.hasAttribute("data-act-pdf-outline-spaces")) return;
      const walker = document.createTreeWalker(heading, NodeFilter.SHOW_TEXT);
      const textNodes = [];
      while (walker.nextNode()) textNodes.push(walker.currentNode);
      textNodes.forEach((node) => {
        node.data = node.data.replace(/ /g, " " + softBreak);
      });
      heading.querySelectorAll("br").forEach((lineBreak) => {
        lineBreak.after(document.createTextNode(" " + softBreak));
      });
      heading.setAttribute("data-act-pdf-outline-spaces", "true");
    });

    document.querySelectorAll(".pdf-page section.slide").forEach((slide) => {
      slide.setAttribute("aria-hidden", "false");
    });
    document.querySelectorAll("h3, h4, h5, h6").forEach((heading) => {
      heading.setAttribute("aria-hidden", "true");
    });

    document.querySelectorAll(".pdf-page").forEach((page) => {
      const h1 = page.querySelector("h1");
      if (h1) previousH2 = null;

      page.querySelectorAll("h2").forEach((heading) => {
        const label = text(heading);
        const duplicate = !label || label === previousH2;
        heading.setAttribute("aria-hidden", String(duplicate));
        if (duplicate) {
          duplicates += 1;
          return;
        }
        previousH2 = label;
        headings += 1;
      });
    });

    return { h2: headings, duplicateH2: duplicates };
  })()`;
}

export function headingUnderlinePreparationExpression() {
  return `(() => {
    const measure = window.__actMeasureHeadingUnderlines;
    if (typeof measure !== "function") return { measured: false };
    return Promise.resolve(measure()).then(() => ({ measured: true }));
  })()`;
}

export function pdfPageViewportExpression() {
  return `(() => {
    const page = document.querySelector(".pdf-page");
    if (!page) return null;
    const rect = page.getBoundingClientRect();
    const width = Math.ceil(rect.width);
    const height = Math.ceil(rect.height);
    return width > 0 && height > 0 ? { width, height } : null;
  })()`;
}

export async function printPdf(cdp, { output, timeoutMs = 15000, url, outlineH1H2 = false }) {
  if (url) await navigate(cdp, url);
  await waitForReveal(cdp, { timeoutMs, requirePrintPages: true });
  await new Promise((resolve) => setTimeout(resolve, 500));
  const viewport = await evaluate(cdp, pdfPageViewportExpression());
  if (viewport) {
    // Print-time viewport units resolve against the physical page, not
    // Chrome's small default headless viewport. Match that page before
    // measuring headings so their wrapping is identical in Page.printToPDF.
    await cdp.send("Emulation.setDeviceMetricsOverride", {
      ...viewport,
      deviceScaleFactor: 1,
      mobile: false,
    });
  }
  await evaluate(cdp, headingUnderlinePreparationExpression());
  const outline = outlineH1H2 ? await evaluate(cdp, h1H2OutlinePreparationExpression()) : undefined;
  const pdf = await cdp.send("Page.printToPDF", pdfPrintOptions({ outlineH1H2 }));
  if (!pdf.stream) throw new Error("Chrome did not return a PDF stream");
  const chunks = [];
  let eof = false;
  while (!eof) {
    const chunk = await cdp.send("IO.read", { handle: pdf.stream, size: 65536 });
    chunks.push(Buffer.from(chunk.data || "", chunk.base64Encoded ? "base64" : "utf8"));
    eof = Boolean(chunk.eof);
  }
  await cdp.send("IO.close", { handle: pdf.stream });
  await fs.writeFile(output, Buffer.concat(chunks));
  return { bytes: (await fs.stat(output)).size, pages: await evaluate(cdp, "document.querySelectorAll('.pdf-page').length"), outline };
}
