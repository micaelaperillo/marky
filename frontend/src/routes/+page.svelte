<script lang="ts">
	import { resolve } from '$app/paths';
	import { m } from '$lib/paraglide/messages';
</script>

<main class="relative isolate flex-1 overflow-hidden">
	<!-- Background gradient -->
	<div
		class="absolute inset-0 -z-10 bg-linear-to-br from-brand-50 via-white to-violet-50 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950"
	></div>
	<div
		class="absolute -top-32 -right-32 -z-10 h-96 w-96 rounded-full bg-brand-200/40 blur-3xl dark:bg-brand-700/20"
	></div>
	<div
		class="absolute -bottom-32 -left-32 -z-10 h-96 w-96 rounded-full bg-violet-200/40 blur-3xl dark:bg-violet-700/20"
	></div>

	<!-- Hero -->
	<section class="mx-auto max-w-4xl px-6 py-20 text-center sm:py-32">
		<span
			class="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-white/60 px-3 py-1 text-xs font-medium text-brand-700 backdrop-blur dark:border-brand-800 dark:bg-slate-900/60 dark:text-brand-300"
		>
			<span class="h-1.5 w-1.5 rounded-full bg-brand-500"></span>
			{m.home_badge()}
		</span>
		<h1
			class="mt-6 text-5xl font-black tracking-tight text-slate-900 sm:text-6xl md:text-7xl dark:text-white"
		>
			{m.home_titleLine1()} <br />
			<span
				class="bg-linear-to-r from-brand-600 via-violet-600 to-fuchsia-600 bg-clip-text text-transparent dark:from-brand-400 dark:via-violet-400 dark:to-fuchsia-400"
			>
				{m.home_titleLine2()}
			</span>
		</h1>
		<p class="mx-auto mt-6 max-w-2xl text-lg text-slate-600 dark:text-slate-400">
			{m.home_subtitle()}
		</p>
		<div class="mt-10 flex items-center justify-center gap-3">
			<a
				href={resolve('/list')}
				class="group inline-flex items-center gap-2 rounded-xl bg-slate-900 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-slate-900/20 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:bg-white dark:text-slate-900 dark:shadow-black/30 dark:hover:bg-slate-200"
			>
				{m.home_openDashboard()}
				<svg
					class="h-4 w-4 transition group-hover:translate-x-0.5"
					viewBox="0 0 20 20"
					fill="currentColor"
				>
					<path
						fill-rule="evenodd"
						d="M3 10a.75.75 0 01.75-.75h10.638L10.23 5.29a.75.75 0 111.04-1.08l5.5 5.25a.75.75 0 010 1.08l-5.5 5.25a.75.75 0 11-1.04-1.08l4.158-3.96H3.75A.75.75 0 013 10z"
						clip-rule="evenodd"
					/>
				</svg>
			</a>
			<a
				href={resolve('/create')}
				class="rounded-xl border border-slate-200 bg-white/80 px-6 py-3 text-sm font-semibold text-slate-700 backdrop-blur transition hover:bg-white focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-200 dark:hover:bg-slate-900"
			>
				{m.home_createCampaign()}
			</a>
		</div>
	</section>
</main>
