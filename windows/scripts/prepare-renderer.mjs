import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(scriptDirectory, "../..");
const rendererSource = resolve(
  repositoryRoot,
  "Sources/BlackHoleBin/Resources/blackhole.html"
);
const shaderSource = resolve(
  repositoryRoot,
  "Sources/BlackHoleBin/Resources/blackhole.glsl"
);
const outputDirectory = resolve(repositoryRoot, "windows/public/renderer");
const outputFile = resolve(outputDirectory, "blackhole.html");
const injectionToken = "__SHADER_JSON__";

const [html, shader] = await Promise.all([
  readFile(rendererSource, "utf8"),
  readFile(shaderSource, "utf8"),
]);

const tokenCount = html.split(injectionToken).length - 1;
if (tokenCount !== 1) {
  throw new Error(
    `Expected exactly one ${injectionToken} token in the shared renderer; found ${tokenCount}.`
  );
}

const preparedRenderer = html.replace(injectionToken, JSON.stringify(shader));
await mkdir(outputDirectory, { recursive: true });
await writeFile(outputFile, preparedRenderer, "utf8");

console.log(`Prepared shared renderer: ${outputFile}`);
