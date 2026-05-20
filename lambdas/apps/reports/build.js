#!/usr/bin/env node

import "dotenv/config";

import { build } from "esbuild";

import defaults from "../../defaults.build.js";

const define = Object.fromEntries(
    Object.entries(process.env).map(([key, value]) => [
        `process.env.${key}`,
        JSON.stringify(value)
    ])
);

await build({
    entryPoints: ["./src/handler.ts"],
    ...defaults,
    define
});

console.log("⚡Bundle build complete ⚡");
