import { spawn } from "node:child_process";

function waitForOutput(child, pattern, timeoutMs) {
  return new Promise((resolve, reject) => {
    let output = "";
    let timer;
    const onData = (chunk) => {
      output += chunk.toString();
      const match = output.match(pattern);
      if (match) {
        clearTimeout(timer);
        resolve(match);
      }
    };
    const onExit = (code, signal) => {
      clearTimeout(timer);
      reject(new Error(`Chrome exited before CDP was ready (code=${code}, signal=${signal})\n${output}`));
    };
    child.stdout.on("data", onData);
    child.stderr.on("data", onData);
    child.once("error", reject);
    child.once("exit", onExit);
    timer = setTimeout(() => reject(new Error(`Timed out waiting for Chrome CDP\n${output}`)), timeoutMs);
  });
}

export async function launchChrome(executable, {
  userDataDir,
  host = "127.0.0.1",
  timeoutMs = 10000,
  initialUrl = "about:blank",
} = {}) {
  if (!executable) throw new Error("A Chrome executable is required");
  const args = [
    "--headless=new",
    "--disable-gpu",
    "--no-first-run",
    "--no-default-browser-check",
    "--remote-debugging-port=0",
  ];
  if (userDataDir) args.push(`--user-data-dir=${userDataDir}`);
  args.push(initialUrl);
  const child = spawn(executable, args, { stdio: ["ignore", "pipe", "pipe"] });
  let stopped = false;
  const ready = await waitForOutput(child, new RegExp(`DevTools listening on ws://${host.replaceAll(".", "\\.")}:([0-9]+)/`), timeoutMs);
  const port = Number(ready[1]);
  return {
    child,
    port,
    stop: async () => {
      if (stopped || child.exitCode !== null) return;
      stopped = true;
      child.kill("SIGTERM");
      await new Promise((resolve) => {
        const timer = setTimeout(() => { child.kill("SIGKILL"); resolve(); }, 2000);
        child.once("exit", () => { clearTimeout(timer); resolve(); });
      });
    },
  };
}
