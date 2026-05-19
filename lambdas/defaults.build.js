export default /** @type {const} */ ({
    outdir: "./dist",
    bundle: true,
    minify: true,
    sourcemap: false,
    format: "esm",
    platform: "node",
    target: "node24",
    tsconfig: "./tsconfig.json",
    external: /** @type {string[]} */ (['@aws-sdk/client-dynamodb', '@aws-sdk/client-sns']),
    alias: {
        "@shared": "shared/src",
    }
});
