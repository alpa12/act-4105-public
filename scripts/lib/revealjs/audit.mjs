import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { connectToTarget } from "./cdp.mjs";
import { launchChrome } from "./chrome.mjs";
import { createStaticServer, servedUrl } from "./static-server.mjs";
import { enumerateRevealSlides, evaluate, navigate, revealStructureExpression, slideStateExpression, waitForReveal } from "./reveal.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const SITE_ROOT = path.join(ROOT, "site");
const OUTPUT_ROOT = path.join(SITE_ROOT, "_site");
const DEFAULT_REPORT = path.join(ROOT, "docs", "rapport-audit-presentations.md");
const VIEWPORTS = [{ width: 1440, height: 900 }, { width: 1024, height: 768 }];

function parseOptions(argv) {
  const options = { report: DEFAULT_REPORT, waitMs: 30000 };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--chapter") options.chapter = String(argv[++index]).padStart(2, "0");
    else if (argument === "--report") options.report = path.resolve(argv[++index]);
    else if (argument === "--wait") options.waitMs = Number(argv[++index]);
    else if (argument === "--skip-render") options.skipRender = true;
    else if (argument === "--browser-only") options.browserOnly = true;
    else if (argument === "--help" || argument === "-h") options.help = true;
    else throw new Error(`Option inconnue : ${argument}`);
  }
  return options;
}

function usage() {
  return `Usage: scripts/audit-chapter-slides [options]

Options:
  --chapter ID       Auditer un seul chapitre, par exemple 06
  --skip-render      Réutiliser les HTML déjà rendus
  --browser-only     Sauter les contrôles statiques et le rendu
  --report FILE      Chemin du rapport Markdown
  --wait MS          Délai maximal de préparation navigateur (défaut: 30000)
  -h, --help         Afficher cette aide`;
}

function issue(issues, chapter, type, message, details = {}) {
  const { resolution = "", slide = "", observed = "" } = typeof details === "string" ? { observed: details } : details;
  issues.push({ chapter, resolution, slide, type, message, observed });
}

async function readDirectories(directory) {
  return (await fs.readdir(directory, { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}

async function discoverChapters(requested, issues) {
  const directories = await readDirectories(path.join(SITE_ROOT, "chapitres"));
  const numbered = directories.filter((name) => /^\d\d-/.test(name));
  const unexpected = numbered.filter((name) => !/^0[1-9]-/.test(name) && !/^00-/.test(name));
  unexpected.forEach((name) => issue(issues, name.slice(0, 2), "discovery", "Répertoire de chapitre numéroté hors de 01 à 09", name));
  const selected = directories.filter((name) => /^0[1-9]-/.test(name) && (!requested || name.startsWith(`${requested}-`)));
  const expected = requested ? [requested] : Array.from({ length: 9 }, (_, index) => String(index + 1).padStart(2, "0"));
  for (const id of expected) {
    const matches = selected.filter((name) => name.startsWith(`${id}-`));
    if (matches.length !== 1) issue(issues, id, "discovery", `Nombre de répertoires trouvés pour le chapitre ${id}: ${matches.length}`, matches.join(", "));
  }
  return selected.filter((name) => expected.some((id) => name.startsWith(`${id}-`))).map((name) => ({
    id: name.slice(0, 2), name, directory: path.join(SITE_ROOT, "chapitres", name), source: path.join(SITE_ROOT, "chapitres", name, "diapos.qmd"),
    html: path.join(OUTPUT_ROOT, "chapitres", name, "diapos.html"),
  }));
}

function outsideFences(source) {
  const visible = [];
  const chunks = [];
  let inFence = false;
  let current = null;
  for (const line of source.split(/\r?\n/)) {
    if (/^```/.test(line)) {
      if (!inFence) {
        inFence = true;
        current = /^```\{r\b/.test(line) ? [] : null;
      } else {
        if (current) chunks.push(current.join("\n"));
        current = null;
        inFence = false;
      }
      continue;
    }
    if (inFence) current?.push(line);
    else visible.push(line);
  }
  return { visible: visible.join("\n"), chunks };
}

function optionValue(chunk, name) {
  const match = chunk.match(new RegExp(`^#\\|\\s*${name.replace("-", "\\-")}\\s*:\\s*(.*)$`, "m"));
  return match?.[1]?.trim() || "";
}

function hasFigAlt(attributes) {
  return /(?:^|\s)fig-alt\s*=\s*(?:"[^"]*"|'[^']*'|[^\s}]+)/.test(attributes);
}

function isFigureChunk(chunk) {
  if (/^#\|\s*include\s*:\s*false\s*$/m.test(chunk)) return false;
  return /#\|\s*(?:fig-cap|fig-width|fig-height|out-width|out-height)\s*:/.test(chunk) ||
    /#\|\s*label\s*:\s*[^\n]*(?:figure|plot|diagram|graph|trend|timeline)/i.test(chunk) ||
    /(?:ggplot\s*\(|plot\s*\(|grid::grid|diagram\s*\(|two_step_trend|trend_period|rate_level)/.test(chunk);
}

async function auditSource(chapter, issues) {
  let source;
  try { source = await fs.readFile(chapter.source, "utf8"); } catch {
    issue(issues, chapter.id, "source", "Fichier diapos.qmd absent", chapter.source);
    return;
  }
  const { visible, chunks } = outsideFences(source);
  const frontMatter = source.match(/^---\s*\n([\s\S]*?)\n---/m)?.[1] || "";
  if (!/metadata-files:\s*[\s\S]*?\.\.\/_diapos\.yml/.test(frontMatter)) issue(issues, chapter.id, "source", "Héritage de ../_diapos.yml absent", "metadata-files");
  const overviewCount = (visible.match(/progress-overview/g) || []).length;
  if (overviewCount !== 1) issue(issues, chapter.id, "source", "La source doit contenir exactement une vue d’ensemble", String(overviewCount));
  for (const heading of visible.match(/^#\s+.*$/gm) || []) {
    if (!/data-progress-label\s*=\s*(?:"[^"]+"|'[^']+'|[^\s}]+)/.test(heading)) issue(issues, chapter.id, "source", "Section de niveau 1 sans libellé de progression", heading.slice(0, 160));
  }
  if (/<style\b/i.test(visible)) issue(issues, chapter.id, "source", "Balise <style> brute dans la source");
  if (/<u\b/i.test(visible)) issue(issues, chapter.id, "source", "Balise <u> brute dans la source");
  for (const match of visible.matchAll(/!\[[^\]]*\]\(([^)]+)\)(?:\{([^}]*)\})?/g)) {
    const target = match[1].trim();
    if (/^(?:https?:)?\/\//i.test(target)) issue(issues, chapter.id, "source-resource", "Image Markdown distante", target);
    if (!hasFigAlt(match[2] || "")) issue(issues, chapter.id, "source-accessibility", "Image Markdown sans décision fig-alt", target);
  }
  for (const chunk of chunks) {
    if (isFigureChunk(chunk) && !/^[^\n]*#\|\s*fig-alt\s*:/m.test(chunk)) issue(issues, chapter.id, "source-accessibility", "Figure R sans #| fig-alt:", optionValue(chunk, "label"));
  }
  for (const match of visible.matchAll(/<(?:img|script|iframe|source|link)\b[^>]*(?:src|href)\s*=\s*["']([^"']+)["'][^>]*>/gi)) {
    if (/^(?:https?:)?\/\//i.test(match[1])) issue(issues, chapter.id, "source-resource", "Ressource d’affichage distante", match[1]);
  }
  for (const match of visible.matchAll(/url\(\s*["']?([^\s"')]+)["']?\s*\)/gi)) {
    if (/^(?:https?:)?\/\//i.test(match[1])) issue(issues, chapter.id, "source-resource", "Ressource CSS distante", match[1]);
  }
  const chapterCss = frontMatter.match(/chapter-css:\s*([^\s#]+)/)?.[1];
  if (chapterCss && !(await exists(path.join(chapter.directory, chapterCss)))) issue(issues, chapter.id, "source", "chapter-css déclaré mais fichier absent", chapterCss);
}

async function exists(file) {
  try { await fs.access(file); return true; } catch { return false; }
}

function attribute(tag, name) {
  return tag.match(new RegExp(`${name}\\s*=\\s*["']([^"']*)["']`, "i"))?.[1] || "";
}

function resourceFile(htmlFile, resource, siteRoot) {
  const clean = resource.split(/[?#]/, 1)[0];
  if (!clean || /^(?:data:|javascript:|mailto:|#)/i.test(clean)) return null;
  try {
    const url = new URL(clean, "http://127.0.0.1/");
    return clean.startsWith("/") ? path.join(siteRoot, decodeURIComponent(url.pathname).replace(/^\/+/, "")) : path.resolve(path.dirname(htmlFile), decodeURIComponent(clean));
  } catch { return null; }
}

async function auditCss(file, siteRoot, chapter, issues, seen = new Set()) {
  if (seen.has(file) || !(await exists(file))) return;
  seen.add(file);
  let css;
  try { css = await fs.readFile(file, "utf8"); } catch { return; }
  for (const match of css.matchAll(/url\(\s*["']?([^\s"')]+)["']?\s*\)/gi)) {
    const target = match[1];
    if (/^(?:https?:)?\/\//i.test(target)) issue(issues, chapter.id, "html-resource", "Ressource CSS distante", target);
    else {
      const referenced = resourceFile(file, target, siteRoot);
      if (referenced && !(await exists(referenced))) issue(issues, chapter.id, "html-resource", "Ressource CSS locale manquante", path.relative(siteRoot, referenced));
    }
  }
  for (const match of css.matchAll(/@import\s+["']([^"']+)["']/gi)) {
    const imported = resourceFile(file, match[1], siteRoot);
    if (imported && !(await exists(imported))) issue(issues, chapter.id, "html-resource", "Feuille CSS importée manquante", path.relative(siteRoot, imported));
    else if (imported) await auditCss(imported, siteRoot, chapter, issues, seen);
  }
}

async function auditHtml(chapter, issues) {
  if (!(await exists(chapter.html))) {
    issue(issues, chapter.id, "html", "HTML rendu absent", chapter.html);
    return;
  }
  const html = await fs.readFile(chapter.html, "utf8");
  const tags = [...html.matchAll(/<(script|img|source|link|iframe|video|audio|object)\b[^>]*>/gi)].map((match) => match[0]);
  const cssFiles = [];
  for (const tag of tags) {
    const tagName = tag.match(/^<(\w+)/)?.[1]?.toLowerCase();
    const resources = [attribute(tag, "src"), attribute(tag, "data-src")];
    if (tagName === "link") resources.push(attribute(tag, "href"));
    for (const resource of resources.filter(Boolean)) {
      if (/^(?:https?:)?\/\//i.test(resource)) issue(issues, chapter.id, "html-resource", "Ressource d’affichage distante", resource);
      else {
        const file = resourceFile(chapter.html, resource, OUTPUT_ROOT);
        if (file && !(await exists(file))) issue(issues, chapter.id, "html-resource", "Ressource locale manquante", path.relative(OUTPUT_ROOT, file));
        if (tagName === "link" && /stylesheet/i.test(tag) && file) cssFiles.push(file);
      }
    }
    if (tagName === "img" && !/\balt\s*=\s*["']/i.test(tag)) issue(issues, chapter.id, "html-accessibility", "Image HTML sans attribut alt", attribute(tag, "src") || attribute(tag, "data-src"));
  }
  for (const css of cssFiles) await auditCss(css, OUTPUT_ROOT, chapter, issues);
  const overviewCount = [...html.matchAll(/<section\b[^>]*class=["'][^"']*\bprogress-overview\b[^"']*["']/gi)].length;
  if (overviewCount !== 1) issue(issues, chapter.id, "html", "Le HTML doit produire exactement une vue d’ensemble", String(overviewCount));
  if (!/site_libs\/revealjs\/dist\/reveal\.js/.test(html)) issue(issues, chapter.id, "html", "RevealJS absent du HTML");
  if (!/site_libs\/revealjs\/plugin\/.+\.js/.test(html)) issue(issues, chapter.id, "html", "Scripts RevealJS du cours absents du HTML");
  if (!/assets\/vendor\/mathjax\/.+\.js/.test(html)) issue(issues, chapter.id, "html", "MathJax local absent du HTML");
  const stylesheetLinks = [...html.matchAll(/<link\b[^>]*rel=["']stylesheet["'][^>]*href=["']([^"']+)["'][^>]*>/gi)].map((match) => match[1]);
  const sharedIndex = stylesheetLinks.findIndex((href) => /styles\/diapos\.css$/.test(href));
  const cleanIndex = stylesheetLinks.findIndex((href) => /styles\/diapos-clean\.css$/.test(href));
  const localIndex = html.indexOf('data-act-chapter-css');
  if (sharedIndex < 0 || cleanIndex < 0 || (localIndex >= 0 && html.indexOf('styles/diapos-clean.css') > localIndex)) issue(issues, chapter.id, "html-css", "Ordre des feuilles RevealJS partagé/local incorrect");
  if (!/data-act-chapter-css/.test(html) && /chapter-css:/.test(await fs.readFile(chapter.source, "utf8"))) issue(issues, chapter.id, "html-css", "Marqueur data-act-chapter-css absent");
  for (const marker of ["�", "Error running filter", "Quarto render error", "File not found"]) if (html.includes(marker)) issue(issues, chapter.id, "html", "Trace manifeste d’échec de rendu", marker);
}

function slideLabel(state) {
  return state ? `${state.title || "(sans titre)"}` : "(état inconnu)";
}

async function auditBrowser(chapters, issues, options) {
  const server = await createStaticServer({ root: OUTPUT_ROOT });
  const chromePath = process.env.CSK_CHROME;
  if (!chromePath) throw new Error("CSK_CHROME doit pointer vers un exécutable Chrome/Chromium");
  const profile = await fs.mkdtemp(path.join(os.tmpdir(), "act4105-audit-chrome-"));
  let chrome;
  try {
    chrome = await launchChrome(chromePath, { userDataDir: profile, timeoutMs: 15000 });
    const { cdp, connection } = await connectToTarget(chrome.port);
    try {
      for (const viewport of VIEWPORTS) {
        await cdp.send("Emulation.setDeviceMetricsOverride", { width: viewport.width, height: viewport.height, deviceScaleFactor: 1, mobile: false });
        for (const chapter of chapters) {
          const events = [];
          const off = cdp.onEvent((event) => events.push(event));
          const relative = path.relative(OUTPUT_ROOT, chapter.html).replaceAll(path.sep, "/");
          const url = servedUrl(server.baseUrl, relative);
          try {
            await navigate(cdp, url);
            await waitForReveal(cdp, { timeoutMs: options.waitMs });
            const structure = await evaluate(cdp, revealStructureExpression());
            const slides = enumerateRevealSlides(structure || []);
            if (!slides.length) issue(issues, chapter.id, "browser", "Aucune diapositive RevealJS parcourable", "", { resolution: `${viewport.width}×${viewport.height}` });
            for (const index of slides) {
              await evaluate(cdp, `(() => { Reveal.slide(${index.h}, ${index.v}, ${index.f === null ? "undefined" : index.f}); return true; })()`);
              await new Promise((resolve) => setTimeout(resolve, 35));
              const state = await evaluate(cdp, slideStateExpression());
              const slide = `h${index.h}/v${index.v}${index.f === null ? "" : `/f${index.f}`}`;
              if (!state?.ready) issue(issues, chapter.id, "browser", "RevealJS non initialisé pendant le parcours", slideLabel(state), { resolution: `${viewport.width}×${viewport.height}`, slide });
              for (const image of state?.images || []) if (!image.complete || image.naturalWidth <= 0 || image.naturalHeight <= 0) issue(issues, chapter.id, "browser-image", "Image visible sans taille naturelle valide", image.src, { resolution: `${viewport.width}×${viewport.height}`, slide, observed: `${image.naturalWidth}×${image.naturalHeight}` });
              for (const box of (state?.overflow || []).slice(0, 5)) issue(issues, chapter.id, "overflow", "Débordement visible supérieur à la tolérance de 6 px", `${box.tag}: ${box.text}`, { resolution: `${viewport.width}×${viewport.height}`, slide, observed: `left=${box.left.toFixed(1)}, right=${box.right.toFixed(1)}, top=${box.top.toFixed(1)}, bottom=${box.bottom.toFixed(1)}` });
            }
          } catch (error) {
            issue(issues, chapter.id, "browser", error.message, "", { resolution: `${viewport.width}×${viewport.height}` });
          } finally {
            off();
          }
          for (const event of events) {
            const params = event.params || {};
            if (event.method === "Runtime.consoleAPICalled" && ["error", "assert"].includes(params.type)) issue(issues, chapter.id, "console", "Erreur console JavaScript", params.args?.map((arg) => arg.value || arg.description || "").join(" "), { resolution: `${viewport.width}×${viewport.height}` });
            if (event.method === "Runtime.exceptionThrown") {
              const details = params.exceptionDetails || {};
              const exception = details.exception || {};
              const location = [details.url, details.lineNumber, details.columnNumber].filter((value) => value !== undefined && value !== "").join(":");
              const observed = [exception.description || exception.value || details.text || "Exception inconnue", location].filter(Boolean).join(" — ");
              issue(issues, chapter.id, "exception", "Exception JavaScript", { resolution: `${viewport.width}×${viewport.height}`, observed });
            }
            if (event.method === "Network.loadingFailed") issue(issues, chapter.id, "network", "Requête réseau échouée", params.errorText || params.requestId, { resolution: `${viewport.width}×${viewport.height}` });
            if (event.method === "Network.responseReceived" && Number(params.response?.status) >= 400) issue(issues, chapter.id, "network", `Réponse HTTP ${params.response.status}`, params.response.url, { resolution: `${viewport.width}×${viewport.height}` });
            if (event.method === "Network.requestWillBeSent" && /^(?:https?:)?\/\//i.test(params.request?.url || "") && !/^https?:\/\/127\.0\.0\.1(?::\d+)?\//.test(params.request.url)) issue(issues, chapter.id, "network", "Ressource distante demandée par l’affichage", params.request.url, { resolution: `${viewport.width}×${viewport.height}` });
            if (event.method === "Log.entryAdded" && params.entry?.level === "error") issue(issues, chapter.id, "console", "Entrée Log JavaScript en erreur", params.entry.text, { resolution: `${viewport.width}×${viewport.height}` });
          }
        }
      }
    } finally {
      connection.close();
    }
  } finally {
    await chrome?.stop();
    await server.close();
    await fs.rm(profile, { recursive: true, force: true });
  }
}

function runRender(source) {
  return new Promise((resolve, reject) => {
    const child = spawn(path.join(ROOT, "scripts", "quarto"), ["render", source, "--no-cache"], { cwd: ROOT, env: process.env, stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    const collect = (chunk) => { if (output.length < 200000) output += chunk.toString(); };
    child.stdout.on("data", collect);
    child.stderr.on("data", collect);
    child.on("error", reject);
    child.on("close", (code) => code === 0 ? resolve(output) : reject(new Error(`Rendu échoué (${code})\n${output}`)));
  });
}

function markdownReport(chapters, issues, options) {
  const generated = new Date().toISOString();
  const errors = issues.length;
  const lines = ["# Rapport d’audit des présentations", "", `Généré le ${generated}`, "", `- Chapitres audités : ${chapters.map((chapter) => chapter.id).join(", ") || "aucun"}`, `- Résolutions navigateur : 1440×900 et 1024×768`, `- Problèmes détectés : ${errors}`, `- Tolérance de débordement : 6 px`, ""];
  if (!errors) lines.push("## Résultat", "", "Toutes les vérifications demandées ont réussi.", "");
  else {
    lines.push("## Problèmes", "", "| Chapitre | Résolution | Diapositive | Type | Problème | Mesure / détail |", "| --- | --- | --- | --- | --- | --- |");
    for (const item of issues) lines.push(`| ${item.chapter} | ${item.resolution || "—"} | ${item.slide || "—"} | ${item.type} | ${item.message.replaceAll("|", "\\|")} | ${(item.observed || "—").replaceAll("|", "\\|")} |`);
    lines.push("");
  }
  lines.push("## Interprétation", "", "Un audit réussi signifie que les sources, les HTML rendus et les deux parcours Chrome n’ont produit aucune anomalie détectée. Les liens pédagogiques externes ordinaires ne sont pas considérés comme des ressources d’affichage.", "");
  return lines.join("\n");
}

async function main(argv) {
  const options = parseOptions(argv);
  if (options.help) { console.log(usage()); return 0; }
  if (!Number.isFinite(options.waitMs) || options.waitMs < 1000) throw new Error("--wait doit être un nombre d’au moins 1000 ms");
  const issues = [];
  const requested = options.chapter ? options.chapter.padStart(2, "0") : "";
  if (requested && !/^0[1-9]$/.test(requested)) throw new Error("--chapter doit être compris entre 01 et 09");
  const chapters = await discoverChapters(requested, issues);
  if (options.browserOnly) options.skipRender = true;
  if (!options.browserOnly) {
    for (const chapter of chapters) {
      if (!options.skipRender) {
        try { await runRender(path.relative(ROOT, chapter.source)); }
        catch (error) { issue(issues, chapter.id, "render", error.message); continue; }
      }
      await auditSource(chapter, issues);
      await auditHtml(chapter, issues);
    }
  }
  await auditBrowser(chapters, issues, options);
  await fs.mkdir(path.dirname(options.report), { recursive: true });
  await fs.writeFile(options.report, markdownReport(chapters, issues, options));
  console.log(`audit-chapter-slides: ${issues.length ? `${issues.length} problème(s)` : "OK"} — rapport ${options.report}`);
  return issues.length ? 1 : 0;
}

try {
  const options = parseOptions(process.argv.slice(2));
  if (options.help) { console.log(usage()); process.exit(0); }
  process.exitCode = await main(process.argv.slice(2));
} catch (error) {
  console.error(`audit-chapter-slides: ${error.stack || error}`);
  process.exitCode = 2;
}
