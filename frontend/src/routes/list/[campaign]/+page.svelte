<script lang="ts">
	import type { PageProps } from './$types';
	import { resolve } from '$app/paths';
	import ReportView from '$lib/components/reports/ReportView.svelte';

	let { data, params }: PageProps = $props();

	const campaign = $derived(data.campaign);
	const report = $derived(data.report?.report);
	const timeline = $derived(data.sentimentTimeline ?? []);
	const timestamp = $derived(data.report?.timestamp ?? null);

	const slug = $derived(params.campaign);
	const name = $derived(campaign?.name ?? 'Campaign');
</script>

<div class="flex-1">
	<div class="mx-auto max-w-7xl px-6 py-10 sm:px-10 sm:py-14">
		<div class="flex flex-wrap items-center justify-between gap-3">
			<nav class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
				<a
					href={resolve('/list')}
					class="-mx-1 rounded px-1 py-2 hover:text-slate-900 dark:hover:text-white"
				>
					Campaigns
				</a>
				<span>/</span>
				<span class="font-medium text-slate-900 dark:text-white">{name}</span>
			</nav>

			<a
				href={resolve('/list/[campaign]/reports', { campaign: slug })}
				class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white shadow-xs transition hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
			>
				View past reports
			</a>
		</div>

		<ReportView {campaign} {report} {timeline} {timestamp} variant="latest" />
	</div>
</div>
