import { paraglideVitePlugin } from '@inlang/paraglide-js';
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';
import devtoolsJson from 'vite-plugin-devtools-json';

export default defineConfig({
	plugins: [
		tailwindcss(),
		sveltekit(),
		devtoolsJson(),
		paraglideVitePlugin({
			outdir: './src/lib/paraglide',
			project: './project.inlang',
			strategy: ['localStorage', 'preferredLanguage', 'globalVariable', 'baseLocale']
		})
	],
	server: {
		proxy: {
			'/api': 'http://localhost:3001'
		}
	}
});
