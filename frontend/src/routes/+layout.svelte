<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import TopBar from '$lib/components/TopBar.svelte';

	let { children } = $props();

	// Inline script: runs before hydration to avoid a light-mode flash.
	const themeInit = `
		(function() {
			try {
				var t = localStorage.getItem('marky.theme');
				if (t !== 'light' && t !== 'dark') {
					t = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
				}
				if (t === 'dark') document.documentElement.classList.add('dark');
				document.documentElement.style.colorScheme = t;
			} catch (_) {}
		})();
	`;
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Marky · Marketing Dashboard</title>
	{@html `<script>${themeInit}</script>`}
</svelte:head>

<div
	class="flex min-h-screen flex-col bg-slate-50 text-slate-900 antialiased transition-colors dark:bg-slate-950 dark:text-slate-100"
>
	<TopBar />
	<div class="flex flex-1 flex-col">
		{@render children()}
	</div>
</div>
