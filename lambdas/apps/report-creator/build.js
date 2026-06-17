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
    // @google/genai (via google-auth-library) does a dynamic require() at import
    // time. esbuild's ESM output shims dynamic require to throw unless a real
    // `require` is in scope, so recreate one from import.meta.url.
    banner: {
        js: "import { createRequire as __createRequire } from 'module'; const require = __createRequire(import.meta.url);"
    },
    define
});

console.log("⚡Bundle build complete ⚡");
