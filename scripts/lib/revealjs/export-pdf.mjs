import { launchChrome } from "./chrome.mjs";
import { connectToTarget } from "./cdp.mjs";
import { printPdf } from "./pdf.mjs";

function options(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--chrome") result.chrome = argv[++index];
    else if (argument === "--port") result.port = Number(argv[++index]);
    else if (argument === "--path") result.path = argv[++index];
    else if (argument === "--out") result.out = argv[++index];
    else if (argument === "--wait") result.waitMs = Number(argv[++index]);
    else if (argument === "--profile") result.profile = argv[++index];
    else if (argument === "--outline-h1-h2") result.outlineH1H2 = true;
    else if (argument === "--help" || argument === "-h") result.help = true;
    else throw new Error(`Unknown option: ${argument}`);
  }
  return result;
}

const config = options(process.argv.slice(2));
if (config.help) {
  console.log("Usage: export-pdf.mjs --chrome FILE --port PORT --path /deck.html?print-pdf --out FILE [--wait MS --profile DIR --outline-h1-h2]");
  process.exit(0);
}
if (!config.chrome || !config.port || !config.path || !config.out) throw new Error("Chrome, port, path and output are required");

let chrome;
let cdp;
let connection;
try {
  chrome = await launchChrome(config.chrome, { userDataDir: config.profile });
  ({ cdp, connection } = await connectToTarget(chrome.port));
  const url = `http://127.0.0.1:${config.port}${config.path.startsWith("/") ? config.path : `/${config.path}`}`;
  const result = await printPdf(cdp, {
    output: config.out,
    timeoutMs: config.waitMs || 15000,
    url,
    outlineH1H2: config.outlineH1H2,
  });
  if (!result.bytes) throw new Error("PDF output is empty");
  console.error(`export-pdf: ${result.pages} page(s), ${result.bytes} byte(s) -> ${config.out}`);
  if (result.outline) console.error(`export-pdf: H1/H2 outline (${result.outline.h2} H2, ${result.outline.duplicateH2} consecutive duplicate(s) omitted)`);
} finally {
  connection?.close();
  await chrome?.stop();
}
