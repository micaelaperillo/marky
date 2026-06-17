<script lang="ts">
	import type { PageProps } from './$types';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { apiFetch } from '$lib/api';
	import ReportView from '$lib/components/reports/ReportView.svelte';
	import { m } from '$lib/paraglide/messages';

	let { data, params }: PageProps = $props();

	const campaign = $derived(data.campaign);
	const report = $derived(data.report?.report);
	const timeline = $derived(data.sentimentTimeline ?? []);
	const timestamp = $derived(data.report?.timestamp ?? null);

	const slug = $derived(params.campaign);
	const name = $derived(campaign?.name ?? 'Campaign');

	let deleting = $state(false);

	async function handleDelete() {
		if (!confirm(m.campaign_deleteConfirm())) return;

		deleting = true;
		try {
			const res = await apiFetch(`/campaigns/${slug}`, { method: 'DELETE' });
			if (res.ok) {
				goto(resolve('/list'));
			} else {
				alert(m.create_errorUnknown());
			}
		} catch {
			alert(m.create_errorNetwork());
		} finally {
			deleting = false;
		}
	}
</script>

<div class="flex-1">
	<div class="mx-auto max-w-7xl px-6 py-10 sm:px-10 sm:py-14">
		<div class="flex flex-wrap items-center justify-between gap-3">
			<nav class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
				<a
					href={resolve('/list')}
					class="-mx-1 rounded px-1 py-2 hover:text-slate-900 dark:hover:text-white"
				>
					{m.campaign_breadcrumb()}
				</a>
				<span>/</span>
				<span class="font-medium text-slate-900 dark:text-white">{name}</span>
			</nav>

			<div class="flex items-center gap-3">
				<button
					onclick={handleDelete}
					disabled={deleting}
					class="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-rose-600 shadow-xs transition hover:bg-rose-50 disabled:opacity-50 dark:border-slate-800 dark:bg-slate-900 dark:text-rose-400 dark:hover:bg-rose-950/30"
				>
					<svg
						class="h-4 w-4"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
					>
						<path d="M3 6h18" />
						<path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" />
						<path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
					</svg>
					{deleting ? m.campaign_deleting() : m.common_delete()}
				</button>

				<a
					href={resolve('/list/[campaign]/reports', { campaign: slug })}
					class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white shadow-xs transition hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
				>
					View past reports
				</a>
			</div>
		</div>

		<ReportView {campaign} {report} {timeline} {timestamp} variant="latest" />
	</div>
</div>
