#!/usr/bin/env node

import "dotenv/config";

import { build } from "esbuild";

const VALID_IDENTIFIER = /^[A-Za-z_$][\w$]*$/;

const define = Object.fromEntries(
    Object.entries(process.env)
        .filter(([key]) => VALID_IDENTIFIER.test(key))
        .map(([key, value]) => [`process.env.${key}`, JSON.stringify(value)])
);

await build({
    entryPoints: ["./src/handler.ts"],
    outdir: "./dist",
    bundle: true,
    minify: true,
    sourcemap: false,
    format: "esm",
    platform: "node",
    target: "node20",
    external: ["@aws-sdk/*"],
    tsconfig: "./tsconfig.json",
    define
});

console.log("Bundle build complete");