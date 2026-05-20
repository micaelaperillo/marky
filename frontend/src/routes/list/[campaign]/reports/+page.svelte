<script lang="ts">
	import type { PageProps } from './$types';
	import { resolve } from '$app/paths';
	import { goto } from '$app/navigation';
	import DateRangeFilter from '$lib/components/reports/DateRangeFilter.svelte';

	let { data, params }: PageProps = $props();

	const campaign = $derived(data.campaign);
	const slug = $derived(params.campaign);
	const name = $derived(campaign?.name ?? 'Campaign');

	type Item = {
		timestamp: string;
		score: number;
		label?: string;
	};

	const items = $derived<Item[]>(
		data.mode === 'default'
			? data.points.map((p) => ({ timestamp: p.timestamp, score: p.sentiment }))
			: data.reports.map((r) => {
					const inner = r.report as { sentiment?: { label?: string; score?: number } } | undefined;
					const innerScore = inner?.sentiment?.score;
					return {
						timestamp: r.timestamp,
						score: typeof innerScore === 'number' ? innerScore : r.sentiment,
						label: inner?.sentiment?.label
					};
				})
	);

	const initialStart = $derived(data.mode === 'range' ? data.range.start.slice(0, 10) : '');
	const initialEnd = $derived(data.mode === 'range' ? data.range.end.slice(0, 10) : '');

	function fmtItemDate(value: string) {
		return new Intl.DateTimeFormat('es-AR', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		}).format(new Date(value));
	}

	function classifyScore(score: number, providedLabel?: string): string {
		if (providedLabel) return providedLabel;
		if (score >= 0.15) return 'Positive';
		if (score <= -0.15) return 'Negative';
		return 'Neutral';
	}

	function badgeClass(label: string): string {
		if (label === 'Positive')
			return 'text-emerald-600 bg-emerald-50 dark:bg-emerald-950/30 dark:text-emerald-400';
		if (label === 'Negative')
			return 'text-rose-600 bg-rose-50 dark:bg-rose-950/30 dark:text-rose-400';
		return 'text-amber-600 bg-amber-50 dark:bg-amber-950/30 dark:text-amber-400';
	}

	function applyRange(range: { start: string; end: string }) {
		const qs = `?start=${encodeURIComponent(range.start)}&end=${encodeURIComponent(range.end)}`;
		// eslint-disable-next-line svelte/no-navigation-without-resolve -- resolve() is inlined; rule cannot see through string concat
		goto(`${resolve('/list/[campaign]/reports', { campaign: slug })}${qs}`);
	}

	function resetRange() {
		goto(resolve('/list/[campaign]/reports', { campaign: slug }));
	}

	const emptyMessage = $derived(
		data.mode === 'range' ? 'No reports in this range.' : 'No reports yet.'
	);
</script>

<div class="flex-1">
	<div class="mx-auto max-w-7xl px-6 py-10 sm:px-10 sm:py-14">
		<nav class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
			<a
				href={resolve('/list')}
				class="-mx-1 rounded px-1 py-2 hover:text-slate-900 dark:hover:text-white"
			>
				Campaigns
			</a>
			<span>/</span>
			<a
				href={resolve('/list/[campaign]', { campaign: slug })}
				class="-mx-1 rounded px-1 py-2 hover:text-slate-900 dark:hover:text-white"
			>
				{name}
			</a>
			<span>/</span>
			<span class="font-medium text-slate-900 dark:text-white">Past reports</span>
		</nav>

		<h1 class="mt-4 text-3xl font-black tracking-tight text-slate-900 dark:text-white">
			Past reports
		</h1>

		<p class="mt-2 text-sm text-slate-500 dark:text-slate-400">
			{data.mode === 'default' ? 'Showing the 5 most recent reports.' : 'Filtered by date range.'}
		</p>

		<div class="mt-6">
			<DateRangeFilter {initialStart} {initialEnd} onApply={applyRange} onReset={resetRange} />
		</div>

		<section class="mt-8">
			{#if items.length === 0}
				<div
					class="rounded-2xl border border-dashed border-slate-300 bg-white p-10 text-center dark:border-slate-700 dark:bg-slate-900"
				>
					<p class="text-sm text-slate-500 dark:text-slate-400">{emptyMessage}</p>
				</div>
			{:else}
				<ul class="space-y-3">
					{#each items as item (item.timestamp)}
						{@const label = classifyScore(item.score, item.label)}
						<li>
							<a
								href={resolve('/list/[campaign]/reports/[timestamp]', {
									campaign: slug,
									timestamp: encodeURIComponent(item.timestamp)
								})}
								class="group flex items-center justify-between gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-xs transition hover:-translate-y-0.5 hover:border-brand-300 dark:border-slate-800 dark:bg-slate-900 dark:hover:border-brand-500"
							>
								<div class="flex flex-col">
									<span
										class="text-xs font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400"
									>
										Report
									</span>
									<span class="mt-1 text-base font-semibold text-slate-900 dark:text-white">
										{fmtItemDate(item.timestamp)}
									</span>
								</div>

								<div class="flex items-center gap-3">
									<div class="flex flex-col items-end">
										<span class="text-2xl font-black text-slate-900 dark:text-white">
											{Math.round(item.score * 100)}%
										</span>
										<span
											class="mt-1 rounded-full px-2.5 py-1 text-xs font-semibold {badgeClass(
												label
											)}"
										>
											{label}
										</span>
									</div>

									<span
										class="rounded-xl border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 transition group-hover:border-brand-400 group-hover:text-brand-600 dark:border-slate-700 dark:text-slate-200"
									>
										View report
									</span>
								</div>
							</a>
						</li>
					{/each}
				</ul>
			{/if}
		</section>
	</div>
</div>
