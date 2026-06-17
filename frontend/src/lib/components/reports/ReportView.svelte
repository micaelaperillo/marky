<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { fmt, campaignStatus, daysUntilStart } from '$lib/utils/date';
	import SentimentChart from '$lib/components/reports/SentimentChart.svelte';
	import SentimentPill from '$lib/components/SentimentPill.svelte';
	import SentimentPie from '$lib/components/reports/SentimentPie.svelte';
	import { m } from '$lib/paraglide/messages';

	type Sentiment = {
		label?: string;
		score?: number;
	};

	type MainTopic = {
		topic: string;
		percent: number;
	};

	type KeyComment = {
		text: string;
		author: string;
		score: number;
	};

	type ReportPayload = {
		sentiment?: Sentiment;
		posts_analyzed?: number;
		key_comments?: KeyComment[];
		analysis?: {
			summary?: string;
			main_topics?: MainTopic[];
		};
		generated_at?: string;
	};

	type CampaignLike = {
		id?: string;
		name?: string;
		topics?: string[];
		start?: string;
		end?: string;
		start_date?: string;
		end_date?: string;
		frequencyMin?: number;
	};

	type TimelinePoint = {
		timestamp: string;
		sentiment: number;
	};

	let {
		campaign,
		report,
		timeline = [],
		variant = 'latest',
		timestamp = null
	}: {
		campaign: CampaignLike;
		report: ReportPayload | null | undefined;
		timeline?: TimelinePoint[];
		variant?: 'latest' | 'historic';
		timestamp?: string | null;
	} = $props();

	const topics = $derived<string[]>(campaign?.topics ?? []);
	const start = $derived(campaign?.start_date ?? campaign?.start);
	const end = $derived(campaign?.end_date ?? campaign?.end);
	const status = $derived(campaignStatus({ start, end }));
	const untilStart = $derived(daysUntilStart(start));

	const sentiment = $derived(report?.sentiment);
	const mainTopics = $derived<MainTopic[]>(report?.analysis?.main_topics ?? []);
	const keyComments = $derived<KeyComment[]>(report?.key_comments ?? []);
	const summary = $derived(report?.analysis?.summary ?? 'No report available yet.');

	const sentimentPanelLabel = $derived(variant === 'latest' ? 'Latest sentiment' : 'Sentiment');

	function fmtDateTime(value?: string) {
		if (!value) return '—';

		return new Intl.DateTimeFormat('es-AR', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		}).format(new Date(value));
	}

	const updateInterval = $derived(campaign?.frequencyMin ?? 60);
	
	let now = $state(Date.now());
	$effect(() => {
		const interval = setInterval(() => {
			now = Date.now();
		}, 10000); // Update every 10 seconds for smoothness
		return () => clearInterval(interval);
	});

const nextUpdateMinutes = $derived.by(() => {
	if (!timestamp) return null;

	const reportTime = new Date(timestamp).getTime();
	const nextUpdateAt = reportTime + updateInterval * 60 * 1000;
	const remainingMs = nextUpdateAt - now;
	
	return Math.ceil(remainingMs / (60 * 1000));
});

const isNewReportLikelyReady = $derived(nextUpdateMinutes !== null && nextUpdateMinutes <= 0);

</script>

{#if isNewReportLikelyReady && variant === 'latest'}
	<div class="mt-8 mb-10 flex items-center justify-between gap-4 rounded-2xl border border-brand-200 bg-brand-50 px-6 py-4 text-brand-800 shadow-sm animate-in fade-in slide-in-from-top-4 duration-500 dark:border-brand-900/50 dark:bg-brand-950/30 dark:text-brand-300">
		<div class="flex items-center gap-3">
			<div class="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 dark:bg-brand-900/50">
				<svg class="h-4 w-4 animate-spin-[3s_linear_infinite]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
					<path d="M21 12a9 9 0 1 1-6.219-8.56" />
					<polyline points="21 3 21 9 12 9" />
				</svg>
			</div>
			<p class="text-sm font-medium">A new report should be ready! Refresh to see the latest data.</p>
		</div>
		<button 
			onclick={() => window.location.reload()}
			class="rounded-lg bg-brand-600 px-4 py-2 text-xs font-bold text-white transition hover:bg-brand-700 active:scale-95 dark:bg-brand-500"
		>
			REFRESH NOW
		</button>
	</div>
{/if}

<section
	class="relative mt-8 overflow-hidden rounded-3xl border border-slate-200 bg-linear-to-br from-white via-brand-50/40 to-violet-50/40 p-8 shadow-xs dark:border-slate-800 dark:from-slate-900 dark:via-brand-950/20 dark:to-violet-950/20"
>
	<div class="relative flex flex-wrap items-start justify-between gap-6">
		<div class="flex-1 min-w-0">
			<div class="flex items-center justify-between gap-4">
				<p class="text-xs font-medium tracking-wide text-brand-600 uppercase dark:text-brand-400">
					Bluesky campaign
				</p>
				
				{#if campaign?.frequencyMin}
					<span
						class="inline-flex items-center rounded-md bg-amber-50 px-2.5 py-1 text-[10px] font-bold tracking-tight text-amber-700 ring-1 ring-amber-400/20 ring-inset dark:bg-amber-900/30 dark:text-amber-300"
					>
						<svg
							class="mr-1.5 h-3.5 w-3.5"
							viewBox="0 0 24 24"
							fill="none"
							stroke="currentColor"
							stroke-width="2.5"
							stroke-linecap="round"
							stroke-linejoin="round"
						>
							<circle cx="12" cy="12" r="10" />
							<polyline points="12 6 12 12 16 14" />
						</svg>
						EVERY {campaign.frequencyMin}M
					</span>
				{/if}
			</div>

			<h1
				class="mt-2 text-4xl font-black tracking-tight text-slate-900 sm:text-5xl dark:text-white truncate"
			>
				{campaign?.name ?? 'Campaign'}
			</h1>

			<div
				class="mt-6 flex flex-wrap items-center gap-6 text-sm text-slate-600 dark:text-slate-400"
			>
				<span class="font-medium text-slate-900 dark:text-slate-200">{fmt(start)} → {fmt(end)}</span>

				<span class="inline-flex items-center gap-1.5">
					<span
						class="h-1.5 w-1.5 rounded-full {status === 'active'
							? 'bg-emerald-500'
							: status === 'pending'
								? 'bg-amber-500'
								: 'bg-slate-400'}"
					></span>
					{status === 'active'
						? m.campaign_statusActive()
						: status === 'pending'
							? m.campaign_statusPending()
							: m.campaign_statusEnded()}
				</span>

				{#if status === 'pending'}
					<span class="inline-flex items-center gap-1.5 text-amber-600 dark:text-amber-400">
						<span class="h-2 w-2 rounded-full bg-amber-500"></span>
						{untilStart === 0
							? m.list_badgeStartsToday()
							: m.list_badgeStartsIn({ days: untilStart ?? 0 })}
					</span>
				{:else if variant === 'latest' && status === 'active'}
					<span class="inline-flex items-center gap-1.5 text-brand-600 dark:text-brand-400">
						<span class="h-2 w-2 animate-pulse rounded-full bg-brand-500"></span>
						Next update in {nextUpdateMinutes} min
					</span>
				{/if}
			</div>
		</div>

		{#if sentiment}
			<div
				class="rounded-2xl border border-slate-200 bg-white p-6 shadow-xs dark:border-slate-800 dark:bg-slate-900"
			>
				<p class="text-xs font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
					{sentimentPanelLabel}
				</p>

				<div class="mt-3 flex items-end gap-3">
					<p class="text-4xl font-black text-slate-900 dark:text-white">
						{Math.round((sentiment.score ?? 0) * 100)}%
					</p>
					<span class="mb-1">
						<SentimentPill score={sentiment.score ?? 0} />
					</span>
				</div>
			</div>
		{/if}
	</div>
</section>

<section class="mt-8 grid grid-cols-1 gap-4 md:grid-cols-4">
	<div
		class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900"
	>
		<p class="text-xs font-semibold text-slate-500 uppercase dark:text-slate-400">Posts analyzed</p>
		<p class="mt-2 text-3xl font-black text-slate-900 dark:text-white">
			{report?.posts_analyzed ?? 0}
		</p>
	</div>

	<div
		class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900"
	>
		<p class="text-xs font-semibold text-slate-500 uppercase dark:text-slate-400">Key comments</p>
		<p class="mt-2 text-3xl font-black text-slate-900 dark:text-white">{keyComments.length}</p>
	</div>

	<div
		class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900"
	>
		<p class="text-xs font-semibold text-slate-500 uppercase dark:text-slate-400">Main topics</p>
		<p class="mt-2 text-3xl font-black text-slate-900 dark:text-white">{mainTopics.length}</p>
	</div>

	<div
		class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900"
	>
		<p class="text-xs font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
			Report updates
		</p>

		<div class="mt-3 space-y-2">
			<div>
				<p class="text-xs text-slate-500 dark:text-slate-400">Last update</p>

				<p class="text-lg font-black text-slate-900 dark:text-white">
					{fmtDateTime(timestamp?? report?.generated_at)}
				</p>
			</div>
		</div>
	</div>
</section>

<section class="mt-8 grid grid-cols-1 items-start gap-6 lg:grid-cols-3">
	<div
		class="rounded-2xl border border-slate-200 bg-white p-6 lg:col-span-2 dark:border-slate-800 dark:bg-slate-900"
	>
		<h2 class="text-sm font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
			Executive summary
		</h2>

		<p class="mt-4 leading-7 text-slate-700 dark:text-slate-300">
			{summary}
		</p>

		{#if topics.length}
			<div class="mt-6 flex flex-wrap gap-2">
				{#each topics as topic (topic)}
					<span
						class="rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-300"
					>
						{topic}
					</span>
				{/each}
			</div>
		{/if}
	</div>

	<div class="space-y-6">
		<div
			class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900"
		>
			<h2 class="text-sm font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
				Topic distribution
			</h2>

			<div class="mt-5 space-y-4">
				{#each mainTopics as item (item.topic)}
					<div>
						<div class="mb-1 flex justify-between text-sm">
							<span class="font-medium text-slate-800 dark:text-slate-200">{item.topic}</span>
							<span class="text-slate-500 dark:text-slate-400">{item.percent}%</span>
						</div>

						<div class="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
							<div class="h-full rounded-full bg-brand-600" style={`width: ${item.percent}%`}></div>
						</div>
					</div>
				{:else}
					<p class="text-sm text-slate-500 dark:text-slate-400">No topic data yet.</p>
				{/each}
			</div>
		</div>

		{#if keyComments.length > 0}
			<div
				class="rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900"
			>
				<h2 class="text-sm font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
					{m.sentiment_pieTitle()}
				</h2>
				<div class="mt-6">
					<SentimentPie comments={keyComments} />
				</div>
			</div>
		{/if}
	</div>
</section>

{#if timeline.length > 1}
			<section class="mt-8 rounded-2xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-900">
			<div class="flex items-center justify-between">
				<h2 class="text-lg font-bold text-slate-900 dark:text-white">
					Sentiment timeline
				</h2>

				<span class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 dark:border-slate-700 dark:text-slate-300">
					Latest {timeline.length} updates
				</span>
			</div>

			<div class="mt-6">
				<SentimentChart
					points={timeline}
					onPointClick={campaign?.id
						? (ts) =>
								goto(
									resolve('/list/[campaign]/reports/[timestamp]', {
										campaign: campaign.id as string,
										timestamp: encodeURIComponent(ts)
									})
								)
						: undefined}
				/>
			</div>
		</section>
{/if}

<section class="mt-8">
	<h2 class="text-sm font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
		Key Bluesky comments
	</h2>

	<div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
		{#each keyComments as comment, idx (idx)}
			<article
				class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900"
			>
				<p class="leading-6 text-slate-800 dark:text-slate-200">
					“{comment.text}”
				</p>

				<div class="mt-4 flex items-center justify-between gap-3 text-sm">
					<span class="font-medium text-brand-600 dark:text-brand-400">
						@{comment.author}
					</span>

					<SentimentPill score={comment.score} size="sm" />
				</div>
			</article>
		{:else}
			<p class="text-sm text-slate-500 dark:text-slate-400">No key comments selected yet.</p>
		{/each}
	</div>
</section>
