<script lang="ts">
	import { page } from '$app/state';
	import { resolve } from '$app/paths';

	import { m } from '$lib/paraglide/messages';

	const code = $derived(page.status === 404 ? '404' : page.status >= 500 ? '500' : 'generic');
	const isNotFound = $derived(page.status === 404);
</script>

<svelte:head>
	<title>{m.errors_code({ code })} - Marky</title>
</svelte:head>

<div class="relative isolate flex flex-1 items-center justify-center overflow-hidden px-6 py-16">
	<!-- Background -->
	<div
		class="absolute inset-0 -z-10 bg-linear-to-br from-slate-50 via-white to-brand-50 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950"
	></div>
	<div
		class="absolute -top-40 -left-40 -z-10 h-112 w-md rounded-full bg-brand-200/30 blur-3xl dark:bg-brand-700/15"
	></div>
	<div
		class="absolute -right-40 -bottom-40 -z-10 h-112 w-md rounded-full bg-violet-200/30 blur-3xl dark:bg-violet-700/15"
	></div>

	<!-- Card -->
	<div class="w-full max-w-xl text-center">
		<p
			class="bg-linear-to-r from-brand-600 via-violet-600 to-fuchsia-600 bg-clip-text text-[8rem] leading-none font-black tracking-tighter text-transparent select-none sm:text-[10rem] dark:from-brand-400 dark:via-violet-400 dark:to-fuchsia-400"
		>
			{m.errors_code({ code })}
		</p>
		<h1 class="mt-2 text-3xl font-black tracking-tight text-slate-900 sm:text-4xl dark:text-white">
			{m.errors_title({ code })}
		</h1>
		<p class="mx-auto mt-4 max-w-md text-slate-600 dark:text-slate-400">
			{m.errors_body({ code })}
		</p>

		{#if page.error?.message && !isNotFound}
			<div
				class="mx-auto mt-6 max-w-md rounded-lg border border-rose-200 bg-rose-50 px-4 py-2 text-left text-xs text-rose-800 dark:border-rose-900/60 dark:bg-rose-950/40 dark:text-rose-300"
			>
				<span class="font-semibold">{m.errors_detail()}:</span>
				{page.error.message}
			</div>
		{/if}

		<div class="mt-8 flex items-center justify-center gap-3">
			<a
				href={resolve('/')}
				class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
			>
				<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
					<path
						fill-rule="evenodd"
						d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z"
						clip-rule="evenodd"
					/>
				</svg>
				{m.common_home()}
			</a>
			<button
				type="button"
				onclick={() => history.back()}
				class="rounded-xl border border-slate-200 bg-white px-5 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800"
			>
				{m.common_back()}
			</button>
		</div>
	</div>
</div>
