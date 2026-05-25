// =========================================================================
//  Render the Mermaid blocks inside diagrams/*.md to PNG and SVG.
//  Uses the mermaid.ink rendering service (no local Chromium needed).
//  Run with:   node render-diagrams.js
//  Output:     diagrams/<basename>.png  and  diagrams/<basename>.svg
// =========================================================================
const fs = require("fs");
const path = require("path");

const DIAG_DIR = path.join(__dirname, "diagrams");
const MERMAID_INK = "https://mermaid.ink";

// pako-based deflate is the safest path for long diagrams; mermaid.ink's
// "pako" route accepts a deflate-raw base64 payload. We fall back to plain
// base64 if pako isn't available.
let pako;
try {
  pako = require("pako");
} catch {
  pako = null;
}

const toUrlSafeBase64 = (buf) =>
  Buffer.from(buf)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");

function encodeForMermaidInk(source) {
  // Mermaid Live Editor / mermaid.ink "pako" payload format
  const state = {
    code: source,
    mermaid: { theme: "default" },
    autoSync: true,
    updateDiagram: true,
  };
  const json = JSON.stringify(state);
  if (pako) {
    const compressed = pako.deflate(json, { level: 9 });
    return { kind: "pako", token: toUrlSafeBase64(compressed) };
  }
  // Plain base64 fallback (works for short diagrams)
  return { kind: "base64", token: toUrlSafeBase64(json) };
}

function extractMermaid(md) {
  const m = md.match(/```mermaid\s*([\s\S]*?)```/);
  return m ? m[1].trim() : null;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchToFile(url, outPath, { retries = 4 } = {}) {
  let lastErr;
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url, { redirect: "follow" });
      if (res.status === 503 || res.status === 429 || res.status >= 500) {
        lastErr = new Error(`HTTP ${res.status} ${res.statusText}`);
        // exponential backoff: 1s, 3s, 7s, 15s
        const wait = 1000 * (2 ** attempt - 1);
        console.log(`   …retry ${attempt}/${retries} after ${wait}ms (got ${res.status})`);
        await sleep(wait);
        continue;
      }
      if (!res.ok) {
        const body = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status} ${res.statusText}\n${body.slice(0, 200)}`);
      }
      const buf = Buffer.from(await res.arrayBuffer());
      fs.writeFileSync(outPath, buf);
      return buf.length;
    } catch (err) {
      lastErr = err;
      await sleep(1500);
    }
  }
  throw lastErr || new Error("Unknown fetch error");
}

function buildUrl(kind, token, format) {
  // format: "img" (PNG) or "svg"
  const prefix = kind === "pako" ? "pako:" : "base64:";
  const base = `${MERMAID_INK}/${format}/${prefix}${token}`;
  // For PNG, force a wide render so the result is crisp on A4. "width" implies internal scaling.
  if (format === "img") return `${base}?bgColor=white&width=2400`;
  return base;
}

async function renderOne(mdFile) {
  const fullPath = path.join(DIAG_DIR, mdFile);
  const md = fs.readFileSync(fullPath, "utf8");
  const code = extractMermaid(md);
  if (!code) {
    console.log(`-  skip ${mdFile} (no mermaid block)`);
    return;
  }

  const base = mdFile.replace(/\.md$/, "");
  const { kind, token } = encodeForMermaidInk(code);

  // PNG
  const pngUrl = buildUrl(kind, token, "img");
  const pngPath = path.join(DIAG_DIR, `${base}.png`);
  const pngSize = await fetchToFile(pngUrl, pngPath);
  console.log(`✓  ${base}.png  (${(pngSize / 1024).toFixed(1)} KB)`);

  // SVG
  const svgUrl = buildUrl(kind, token, "svg");
  const svgPath = path.join(DIAG_DIR, `${base}.svg`);
  const svgSize = await fetchToFile(svgUrl, svgPath);
  console.log(`✓  ${base}.svg  (${(svgSize / 1024).toFixed(1)} KB)`);
}

(async () => {
  if (!pako) {
    console.warn("⚠  'pako' is not installed — long diagrams may fail. Run `npm install pako` for safer encoding.");
  }
  const files = fs
    .readdirSync(DIAG_DIR)
    .filter((f) => f.endsWith(".md") && f !== "README.md")
    .sort();

  for (const f of files) {
    try {
      await renderOne(f);
    } catch (err) {
      console.error(`✗  ${f} failed: ${err.message}`);
    }
  }
  console.log("\nDone.");
})();
