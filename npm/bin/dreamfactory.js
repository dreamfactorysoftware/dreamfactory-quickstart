#!/usr/bin/env node
"use strict";

const crypto = require("crypto");
const fs = require("fs");
const https = require("https");
const os = require("os");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

const packageJson = require("../../package.json");
const repo = process.env.DREAMFACTORY_QUICKSTART_REPO || "dreamfactorysoftware/dreamfactory-quickstart";
const version = process.env.DREAMFACTORY_QUICKSTART_VERSION || `v${packageJson.version}`;
const platform = detectPlatform();
const archiveName = `dreamfactory-quickstart-${platform}.tar.gz`;
const baseUrl = version === "latest"
  ? `https://github.com/${repo}/releases/latest/download`
  : `https://github.com/${repo}/releases/download/${version}`;
const cacheRoot = process.env.DREAMFACTORY_QUICKSTART_CACHE ||
  path.join(os.homedir(), ".cache", "dreamfactory-quickstart");
const installDir = path.join(cacheRoot, version, platform, "dreamfactory-quickstart");
const binaryPath = path.join(installDir, "dreamfactory");

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});

async function main() {
  if (!fs.existsSync(binaryPath)) {
    await install();
  }

  const child = spawn(binaryPath, process.argv.slice(2), {
    stdio: "inherit",
    env: process.env
  });

  child.on("exit", (code, signal) => {
    if (signal) {
      process.kill(process.pid, signal);
      return;
    }
    process.exit(code ?? 1);
  });
}

function detectPlatform() {
  if (process.platform !== "linux" || process.arch !== "x64") {
    throw new Error(
      `DreamFactory Quickstart currently supports Linux x86_64. Detected ${process.platform} ${process.arch}.`
    );
  }
  return "linux-x86_64";
}

async function install() {
  requireCommand("tar");

  const workDir = fs.mkdtempSync(path.join(os.tmpdir(), "dreamfactory-quickstart-"));
  const archivePath = path.join(workDir, archiveName);
  const sumsPath = path.join(workDir, "SHA256SUMS");

  try {
    console.error(`Installing DreamFactory Quickstart ${version} for ${platform}`);
    await download(`${baseUrl}/${archiveName}`, archivePath);
    await download(`${baseUrl}/SHA256SUMS`, sumsPath);
    verifyChecksum(archivePath, sumsPath);

    fs.rmSync(path.dirname(installDir), { recursive: true, force: true });
    fs.mkdirSync(path.dirname(installDir), { recursive: true });

    const extract = spawnSync("tar", ["xzf", archivePath, "-C", path.dirname(installDir)], {
      stdio: "inherit"
    });
    if (extract.status !== 0) {
      throw new Error("Could not extract DreamFactory Quickstart archive.");
    }
    if (!fs.existsSync(binaryPath)) {
      throw new Error("Downloaded archive did not contain a runnable dreamfactory command.");
    }
    fs.chmodSync(binaryPath, 0o755);
  } finally {
    fs.rmSync(workDir, { recursive: true, force: true });
  }
}

function requireCommand(command) {
  const result = spawnSync(command, ["--version"], { stdio: "ignore" });
  if (result.error && result.error.code === "ENOENT") {
    throw new Error(`Missing required command: ${command}`);
  }
}

function verifyChecksum(archivePath, sumsPath) {
  const sums = fs.readFileSync(sumsPath, "utf8").split(/\r?\n/);
  const line = sums.find((entry) => entry.trim().endsWith(`  ${archiveName}`));
  if (!line) {
    throw new Error(`SHA256SUMS does not include ${archiveName}.`);
  }

  const expected = line.trim().split(/\s+/)[0];
  const actual = crypto.createHash("sha256").update(fs.readFileSync(archivePath)).digest("hex");
  if (actual !== expected) {
    throw new Error(`Checksum mismatch for ${archiveName}.`);
  }
}

function download(url, destination) {
  return new Promise((resolve, reject) => {
    const request = https.get(url, (response) => {
      if ([301, 302, 303, 307, 308].includes(response.statusCode || 0)) {
        response.resume();
        download(response.headers.location, destination).then(resolve, reject);
        return;
      }

      if (response.statusCode !== 200) {
        response.resume();
        reject(new Error(`Download failed (${response.statusCode}): ${url}`));
        return;
      }

      fs.mkdirSync(path.dirname(destination), { recursive: true });
      const file = fs.createWriteStream(destination);
      response.pipe(file);
      file.on("finish", () => file.close(resolve));
      file.on("error", reject);
    });

    request.on("error", reject);
  });
}
