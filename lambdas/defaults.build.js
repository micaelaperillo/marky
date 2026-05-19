export default /** @type {const} */ ({
    outdir: "./dist",
    bundle: true,
    minify: true,
    sourcemap: false,
    format: "esm",
    platform: "node",
    target: "node24",
    tsconfig: "./tsconfig.json",
    alias: {
        "@shared": "shared/src",
    }
});
