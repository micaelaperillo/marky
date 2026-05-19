#!/usr/bin/env node

import "dotenv/config";

import { build } from "esbuild";

const define = Object.fromEntries(
    Object.entries(process.env).map(([key, value]) => [
        `process.env.${key}`,
        JSON.stringify(value)
    ])
);

await build({
    entryPoints: ["./src/handler.ts"],
    outdir: "./dist",
    bundle: true,
    minify: true,
    sourcemap: false,
    format: "esm",
    platform: "node",
    target: "node24",
    tsconfig: "./tsconfig.json",
    define
});

console.log("⚡Bundle build complete ⚡");
