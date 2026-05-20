#!/usr/bin/env node

import { build } from "esbuild";

import defaults from "../../defaults.build.js";

await build({
	entryPoints: ["./src/handler.ts"],
	...defaults,
});

console.log("⚡Bundle build complete ⚡");
