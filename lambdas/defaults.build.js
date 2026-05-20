export default /** @type {const} */ ({
	alias: {
		"@shared": "shared/src",
	},
	bundle: true,
	external: /** @type {string[]} */ (["@aws-sdk/*", "http", "express"]),
	format: "cjs",
	minify: true,
	outdir: "./dist",
	platform: "node",
	sourcemap: false,
	target: "node24",
	tsconfig: "./tsconfig.json",
});
