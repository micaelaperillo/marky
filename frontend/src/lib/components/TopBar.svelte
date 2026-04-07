<script lang="ts">
	import Brand from './Brand.svelte';
	import LocaleSwitcher from './LocaleSwitcher.svelte';
	import ThemeToggle from './ThemeToggle.svelte';
</script>

<header
	class="sticky top-0 z-40 border-b border-slate-200/70 bg-white/80 backdrop-blur supports-[backdrop-filter]:bg-white/70 dark:border-slate-800/70 dark:bg-slate-900/80 dark:supports-[backdrop-filter]:bg-slate-900/60"
>
	<div class="mx-auto flex h-14 max-w-7xl items-center justify-between px-6">
		<Brand size="sm" />
		<div class="flex items-center gap-2">
			<ThemeToggle />
			<LocaleSwitcher />
		</div>
	</div>
</header>
