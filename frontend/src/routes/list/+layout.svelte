<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { signOut } from '$lib/auth';
	import { m } from '$lib/paraglide/messages.js';

	let { data, children } = $props();

	function handleSignOut() {
		signOut();
		goto(resolve('/login'));
	}

	const nav = [
		{ href: '/list', label: m.nav_campaigns, icon: 'grid' },
		{ href: '/create', label: m.nav_newCampaign, icon: 'plus' }
	] as const;

	const isActive = (href: (typeof nav)[number]['href']) => {
		const fullHref = resolve(href);
		return fullHref === resolve('/list')
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
					{data.email?.slice(0, 1).toUpperCase() ?? '·'}
				</div>
				<div class="min-w-0 flex-1">
					<p class="truncate text-sm font-medium text-slate-900 dark:text-white">{data.email}</p>
					<p class="text-xs text-slate-500 dark:text-slate-400">{m.common_signedIn()}</p>
				</div>
			</div>
			<button
				onclick={handleSignOut}
				class="mt-3 w-full rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800"
			>
				{m.nav_signOut()}
			</button>
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
	<button
		onclick={handleSignOut}
		class="flex flex-1 flex-col items-center gap-1 py-3 text-xs font-medium text-slate-500 transition hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400"
	>
		<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
			<path
				fill-rule="evenodd"
				d="M3 4.25A2.25 2.25 0 015.25 2h5.5A2.25 2.25 0 0113 4.25v2a.75.75 0 01-1.5 0v-2a.75.75 0 00-.75-.75h-5.5a.75.75 0 00-.75.75v11.5c0 .414.336.75.75.75h5.5a.75.75 0 00.75-.75v-2a.75.75 0 011.5 0v2A2.25 2.25 0 0110.75 18h-5.5A2.25 2.25 0 013 15.75V4.25z"
				clip-rule="evenodd"
			/>
			<path
				fill-rule="evenodd"
				d="M6 10a.75.75 0 01.75-.75h9.546l-1.048-1.047a.75.75 0 111.06-1.06l2.5 2.5a.75.75 0 010 1.06l-2.5 2.5a.75.75 0 11-1.06-1.06l1.048-1.048H6.75A.75.75 0 016 10z"
				clip-rule="evenodd"
			/>
		</svg>
		{m.nav_signOut()}
	</button>
</nav>
