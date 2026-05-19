#!/usr/bin/env node

import { build } from 'esbuild';

await build({
    entryPoints: ['src/index.ts'],
    bundle: true,
    minify: true,
    platform: 'node',
    target: 'node20',
    outfile: 'dist/index.js',
    format: 'esm',
    external: ['@aws-sdk/client-dynamodb'],
    alias: {
        "@shared": "./src/shared",
        "@domains": "./src/domains"
    },
    define: {
        'process.env.NODE_ENV': '"production"'
    }
});
