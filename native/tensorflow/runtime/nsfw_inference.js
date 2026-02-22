#!/usr/bin/env node
const fs = require("fs");
const http = require("http");
const path = require("path");

async function readStdin() {
  return await new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      data += chunk;
    });
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", (err) => reject(err));
  });
}

function toCanonical(predictions) {
  const map = {
    drawings: 0.0,
    hentai: 0.0,
    neutral: 0.0,
    porn: 0.0,
    sexy: 0.0,
  };
  for (const prediction of predictions) {
    const key = String(prediction.className || "").toLowerCase();
    if (Object.prototype.hasOwnProperty.call(map, key)) {
      map[key] = Number(prediction.probability || 0);
    }
  }
  return map;
}

async function main() {
  const tf = require("@tensorflow/tfjs");
  const nsfwjs = require("nsfwjs");
  await tf.setBackend("cpu");
  await tf.ready();

  const payload = await readStdin();
  if (!payload) {
    throw new Error("Empty input payload");
  }
  const req = JSON.parse(payload);
  const modelDir = req.modelDir;
  const frames = req.frames;
  if (!modelDir || !Array.isArray(frames) || frames.length === 0) {
    throw new Error("Invalid request");
  }

  const { server, baseUrl } = await startModelServer(modelDir);
  const model = await nsfwjs.load(`${baseUrl}/model.json`, { size: 0 });
  const results = [];

  for (const frame of frames) {
    const width = Number(frame.width);
    const height = Number(frame.height);
    const raw = Buffer.from(String(frame.rgb), "base64");
    const expected = width * height * 3;
    if (raw.length !== expected) {
      throw new Error(
        `Invalid frame length: got ${raw.length}, expected ${expected}`
      );
    }

    const rgb = new Uint8Array(raw);
    const imageTensor = tf.tensor3d(rgb, [height, width, 3], "int32");
    try {
      const predictions = await model.classify(imageTensor);
      results.push(toCanonical(predictions));
    } finally {
      imageTensor.dispose();
    }
  }

  process.stdout.write(JSON.stringify({ results }));
  await new Promise((resolve) => server.close(resolve));
}

async function startModelServer(modelDir) {
  const server = http.createServer((req, res) => {
    try {
      const requestPath = decodeURIComponent((req.url || "/").split("?")[0]);
      const normalized = path.normalize(requestPath).replace(/^([/\\])+/, "");
      const targetPath = path.join(modelDir, normalized);
      if (!targetPath.startsWith(path.normalize(modelDir))) {
        res.statusCode = 403;
        res.end("Forbidden");
        return;
      }
      if (!fs.existsSync(targetPath) || !fs.statSync(targetPath).isFile()) {
        res.statusCode = 404;
        res.end("Not found");
        return;
      }
      const stream = fs.createReadStream(targetPath);
      stream.on("error", () => {
        res.statusCode = 500;
        res.end("Read error");
      });
      stream.pipe(res);
    } catch (_) {
      res.statusCode = 500;
      res.end("Server error");
    }
  });

  const port = await new Promise((resolve, reject) => {
    server.listen(0, "127.0.0.1", () => {
      const addr = server.address();
      if (!addr || typeof addr === "string") {
        reject(new Error("Failed to bind model server"));
        return;
      }
      resolve(addr.port);
    });
    server.on("error", (err) => reject(err));
  });

  return {
    server,
    baseUrl: `http://127.0.0.1:${port}`,
  };
}

main().catch((err) => {
  process.stderr.write(String(err && err.message ? err.message : err));
  process.exit(1);
});
