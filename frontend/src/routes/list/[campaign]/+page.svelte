<script lang="ts">
	import type { PageProps } from './$types';

	import { resolve } from '$app/paths';
	import { m } from '$lib/paraglide/messages';

	let { data }: PageProps = $props();

	type RawItem = {
		Hash?: { S: string };
		Sort?: { S: string };
		Topics?: { L?: { S: string }[]; SS?: string[] };
		Start?: { S: string };
		End?: { S: string };
	};

	const item = $derived((data.Item ?? {}) as RawItem);
	const name = $derived(item.Sort ?? 'Campaign');
	const topics = $derived<string[]>(
		item.Topics?.L?.map((x) => x?.S).filter((s): s is string => !!s) ?? item.Topics?.SS ?? []
	);
	const start = $derived(item.Start?.S);
	const end = $derived(item.End?.S);
	const exists = $derived(!!item.Sort);

	const daysLeft = $derived.by(() => {
		if (!end) return null;
		const parsed = new Date(end);
		if (Number.isNaN(parsed.getTime())) return null;
		const today = new Date();
		today.setHours(0, 0, 0, 0);
		parsed.setHours(0, 0, 0, 0);
		return Math.round((parsed.getTime() - today.getTime()) / 86_400_000);
	});
	const running = $derived(daysLeft !== null && daysLeft >= 0);

	function fmt(d?: string) {
		if (!d) return '—';
		const parsed = new Date(d);
		if (Number.isNaN(parsed.getTime())) return d;
		return parsed.toLocaleDateString(undefined, {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}
</script>

<div class="flex-1">
	<div class="mx-auto max-w-6xl px-6 py-10 sm:px-10 sm:py-14">
		<!-- Breadcrumb -->
		<nav class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
			<a href={resolve('/list')} class="hover:text-slate-900 dark:hover:text-white">
				{m.campaign_breadcrumb()}
			</a>
			<span>/</span>
			<span class="font-medium text-slate-900 dark:text-white">{name}</span>
		</nav>

		{#if !exists}
			<div
				class="mt-10 rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/30 dark:text-amber-200"
			>
				<h2 class="text-lg font-bold">{m.campaign_notFoundTitle()}</h2>
				<p class="mt-1 text-sm">{m.campaign_notFoundBody()}</p>
				<a
					href={resolve('/list')}
					class="mt-4 inline-flex rounded-lg bg-amber-900 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-950 focus-visible:ring-2 focus-visible:ring-amber-500/40 focus-visible:outline-none dark:bg-amber-200 dark:text-amber-950 dark:hover:bg-amber-100"
				>
					{m.campaign_notFoundCta()}
				</a>
			</div>
		{:else}
			<!-- Header card -->
			<div
				class="relative mt-4 overflow-hidden rounded-3xl border border-slate-200 bg-linear-to-br from-white via-brand-50/40 to-violet-50/40 p-8 shadow-xs dark:border-slate-800 dark:from-slate-900 dark:via-brand-950/20 dark:to-violet-950/20"
			>
				<div
					class="absolute -top-20 -right-20 h-64 w-64 rounded-full bg-brand-200/30 blur-3xl dark:bg-brand-700/15"
				></div>
				<div class="relative flex flex-wrap items-start justify-between gap-4">
					<div>
						<p
							class="text-xs font-medium tracking-wide text-brand-600 uppercase dark:text-brand-400"
						>
							{m.campaign_eyebrow()}
						</p>
						<h1
							class="mt-1 text-4xl font-black tracking-tight text-slate-900 sm:text-5xl dark:text-white"
						>
							{name}
						</h1>
						<div
							class="mt-3 flex flex-wrap items-center gap-4 text-sm text-slate-600 dark:text-slate-400"
						>
							<span class="inline-flex items-center gap-1.5">
								<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
									<path
										fill-rule="evenodd"
										d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z"
										clip-rule="evenodd"
									/>
								</svg>
								{fmt(start)} → {fmt(end)}
							</span>
							<span class="inline-flex items-center gap-1.5">
								<span class="h-1.5 w-1.5 rounded-full {running ? 'bg-emerald-500' : 'bg-slate-400'}"
								></span>
								{running ? m.campaign_statusActive() : m.campaign_statusEnded()}
							</span>
						</div>
					</div>
				</div>
			</div>

			<!-- Topics -->
			<section class="mt-8">
				<h2
					class="text-sm font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400"
				>
					{m.campaign_topicsHeading()}
				</h2>
				<div class="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
					{#each topics as topic (topic)}
						<div
							class="group flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4 transition hover:border-brand-300 hover:shadow-sm dark:border-slate-800 dark:bg-slate-900 dark:hover:border-brand-700"
						>
							<div class="flex items-center gap-3">
								<div
									class="flex h-10 w-10 items-center justify-center rounded-lg bg-linear-to-br from-brand-100 to-violet-100 text-brand-700 dark:from-brand-950/60 dark:to-violet-950/60 dark:text-brand-300"
								>
									<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
										<path d="M2 10a8 8 0 018-8v8h8a8 8 0 11-16 0z" />
										<path d="M12 2.252A8.014 8.014 0 0117.748 8H12V2.252z" />
									</svg>
								</div>
								<div>
									<p class="font-semibold text-slate-900 dark:text-white">{topic}</p>
									<p class="text-xs text-slate-500 dark:text-slate-400">
										{m.campaign_topicSubtitle()}
									</p>
								</div>
							</div>
							<span
								class="text-xs font-medium text-slate-400 group-hover:text-brand-600 dark:group-hover:text-brand-400"
							>
								→
							</span>
						</div>
					{:else}
						<p class="text-sm text-slate-500 dark:text-slate-400">{m.campaign_noTopics()}</p>
					{/each}
				</div>
			</section>

			<!-- Placeholder analytics -->
			<section class="mt-10">
				<h2
					class="text-sm font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400"
				>
					{m.campaign_reportsHeading()}
				</h2>
				<div
					class="mt-4 flex h-64 items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 bg-white text-sm text-slate-500 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-400"
				>
					{m.campaign_reportsPlaceholder()}
				</div>
			</section>
		{/if}
	</div>
</div>
