<script lang="ts">
	import { base, resolve } from '$app/paths';
	import { page } from '$app/state';
	import { m } from '$lib/paraglide/messages.js';

	let { data, children } = $props();

	const nav = [
		{ href: '/list', label: m.nav_campaigns, icon: 'grid' },
		{ href: '/create', label: m.nav_newCampaign, icon: 'plus' }
	] as const;

	const isActive = (href: string) => {
		const fullHref = `${base}${href}`;
		return fullHref === `${base}/list`
			? page.url.pathname === fullHref
			: page.url.pathname.startsWith(fullHref);
	};
</script>

<div class="flex flex-1">
	<!-- Sidebar -->
	<aside
		class="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-64 shrink-0 flex-col border-r border-slate-200 bg-white px-4 py-6 md:flex dark:border-slate-800 dark:bg-slate-900"
	>
		<nav aria-label="Sidebar" class="flex flex-col gap-1">
			{#each nav as item (item.href)}
				{@const active = isActive(item.href)}
				<a
					href={resolve(item.href)}
					class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none {active
						? 'bg-brand-50 text-brand-700 dark:bg-brand-950/50 dark:text-brand-300'
						: 'text-slate-600 hover:bg-slate-50 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-white'}"
				>
					<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
						{#if item.icon === 'grid'}
							<path
								d="M3 4a1 1 0 011-1h5a1 1 0 011 1v5a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 12a1 1 0 011-1h5a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1v-4zM12 4a1 1 0 011-1h3a1 1 0 011 1v4a1 1 0 01-1 1h-3a1 1 0 01-1-1V4zM12 11a1 1 0 011-1h3a1 1 0 011 1v5a1 1 0 01-1 1h-3a1 1 0 01-1-1v-5z"
							/>
						{:else}
							<path
								fill-rule="evenodd"
								d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
								clip-rule="evenodd"
							/>
						{/if}
					</svg>
					{item.label()}
				</a>
			{/each}
		</nav>

		<div
			class="mt-auto rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-800 dark:bg-slate-950"
		>
			<div class="flex items-center gap-3">
				<div
					class="flex h-9 w-9 items-center justify-center rounded-full bg-linear-to-br from-brand-400 to-violet-500 text-sm font-bold text-white"
				>
					{data.user?.slice(0, 2).toUpperCase() ?? '··'}
				</div>
				<div class="min-w-0">
					<p class="truncate text-sm font-medium text-slate-900 dark:text-white">{data.user}</p>
					<p class="text-xs text-slate-500 dark:text-slate-400">{m.common_signedIn()}</p>
				</div>
			</div>
		</div>
	</aside>

	<!-- Main -->
	<main class="flex-1 overflow-x-hidden pb-16 md:pb-0">
		{@render children()}
	</main>
</div>

<!-- Mobile bottom nav -->
<nav
	aria-label="Mobile navigation"
	class="fixed inset-x-0 bottom-0 z-40 flex border-t border-slate-200 bg-white md:hidden dark:border-slate-800 dark:bg-slate-900"
>
	{#each nav as item (item.href)}
		{@const active = isActive(item.href)}
		<a
			href={resolve(item.href)}
			class="flex flex-1 flex-col items-center gap-1 py-3 text-xs font-medium transition focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none {active
				? 'text-brand-700 dark:text-brand-300'
				: 'text-slate-500 dark:text-slate-400'}"
		>
			<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
				{#if item.icon === 'grid'}
					<path
						d="M3 4a1 1 0 011-1h5a1 1 0 011 1v5a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 12a1 1 0 011-1h5a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1v-4zM12 4a1 1 0 011-1h3a1 1 0 011 1v4a1 1 0 01-1 1h-3a1 1 0 01-1-1V4zM12 11a1 1 0 011-1h3a1 1 0 011 1v5a1 1 0 01-1 1h-3a1 1 0 01-1-1v-5z"
					/>
				{:else}
					<path
						fill-rule="evenodd"
						d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
						clip-rule="evenodd"
					/>
				{/if}
			</svg>
			{item.label()}
		</a>
	{/each}
</nav>
