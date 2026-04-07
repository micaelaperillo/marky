<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { t } from '$lib/i18n';

	let { data, children } = $props();

	const nav = [
		{ href: '/list', key: 'nav.campaigns', icon: 'grid' },
		{ href: '/create', key: 'nav.newCampaign', icon: 'plus' }
	] as const;
</script>

<div class="flex flex-1">
	<!-- Sidebar -->
	<aside
		class="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-64 shrink-0 flex-col border-r border-slate-200 bg-white px-4 py-6 md:flex dark:border-slate-800 dark:bg-slate-900"
	>
		<nav class="flex flex-col gap-1">
			{#each nav as item (item.href)}
				{@const active =
					item.href === '/list'
						? page.url.pathname === '/list'
						: page.url.pathname.startsWith(item.href)}
				<a
					href={item.href === '/list' ? resolve('/list') : resolve('/create')}
					class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none {active
						? 'bg-brand-50 text-brand-700 dark:bg-brand-950/50 dark:text-brand-300'
						: 'text-slate-600 hover:bg-slate-50 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-white'}"
				>
					{#if item.icon === 'grid'}
						<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
							<path
								d="M3 4a1 1 0 011-1h5a1 1 0 011 1v5a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 12a1 1 0 011-1h5a1 1 0 011 1v4a1 1 0 01-1 1H4a1 1 0 01-1-1v-4zM12 4a1 1 0 011-1h3a1 1 0 011 1v4a1 1 0 01-1 1h-3a1 1 0 01-1-1V4zM12 11a1 1 0 011-1h3a1 1 0 011 1v5a1 1 0 01-1 1h-3a1 1 0 01-1-1v-5z"
							/>
						</svg>
					{:else}
						<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
							<path
								fill-rule="evenodd"
								d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
								clip-rule="evenodd"
							/>
						</svg>
					{/if}
					{$t(item.key)}
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
					<p class="text-xs text-slate-500 dark:text-slate-400">{$t('common.signedIn')}</p>
				</div>
			</div>
		</div>
	</aside>

	<!-- Main -->
	<main class="flex-1 overflow-x-hidden">
		{@render children()}
	</main>
</div>
