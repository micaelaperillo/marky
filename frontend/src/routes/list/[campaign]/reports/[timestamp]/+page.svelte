<script lang="ts">
	import type { PageProps } from './$types';
	import { resolve } from '$app/paths';
	import ReportView from '$lib/components/reports/ReportView.svelte';

	let { data, params }: PageProps = $props();

	const campaign = $derived(data.campaign);
	const report = $derived(data.report?.report);
	const slug = $derived(params.campaign);
	const name = $derived(campaign?.name ?? 'Campaign');
	const timestamp = $derived(data.report?.timestamp ?? null);

	function fmtBreadcrumbDate(value: string) {
		return new Intl.DateTimeFormat('es-AR', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		}).format(new Date(value));
	}
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
			<a
				href={resolve('/list/[campaign]/reports', { campaign: slug })}
				class="-mx-1 rounded px-1 py-2 hover:text-slate-900 dark:hover:text-white"
			>
				Past reports
			</a>
			<span>/</span>
			<span class="font-medium text-slate-900 dark:text-white">
				{fmtBreadcrumbDate(data.timestamp)}
			</span>
		</nav>

		<ReportView {campaign} {report} timeline={[]} {timestamp} variant="historic" />
	</div>
</div>
