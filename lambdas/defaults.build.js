export default /** @type {const} */ ({
	alias: {
		"@shared": "shared/src",
	},
	banner: {
		js: "import { createRequire } from 'module'; const require = createRequire(import.meta.url);",
	},
	bundle: true,
	external: /** @type {string[]} */ (["@aws-sdk/*"]),
	format: "esm",
	minify: true,
	outdir: "./dist",
	platform: "node",
	sourcemap: false,
	target: "node24",
	tsconfig: "./tsconfig.json",
});
