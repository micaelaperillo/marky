<script lang="ts">
	import { fmt, daysLeft as computeDaysLeft } from '$lib/utils/date';
	import SentimentChart from '$lib/components/reports/SentimentChart.svelte';

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
		name?: string;
		topics?: string[];
		start?: string;
		end?: string;
		start_date?: string;
		end_date?: string;
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
	const remaining = $derived(computeDaysLeft(end));
	const running = $derived(remaining !== null && remaining >= 0);

	const sentiment = $derived(report?.sentiment);
	const mainTopics = $derived<MainTopic[]>(report?.analysis?.main_topics ?? []);
	const keyComments = $derived<KeyComment[]>(report?.key_comments ?? []);
	const summary = $derived(report?.analysis?.summary ?? 'No report available yet.');

	const sentimentPanelLabel = $derived(variant === 'latest' ? 'Latest sentiment' : 'Sentiment');

	const sentimentLabelClass = $derived(
		sentiment?.label === 'Positive'
			? 'text-emerald-600 bg-emerald-50 dark:bg-emerald-950/30 dark:text-emerald-400'
			: sentiment?.label === 'Negative'
				? 'text-rose-600 bg-rose-50 dark:bg-rose-950/30 dark:text-rose-400'
				: 'text-amber-600 bg-amber-50 dark:bg-amber-950/30 dark:text-amber-400'
	);

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

	const minutesSinceGenerated = $derived.by(() => {
		if (!timestamp) return null;
		return Math.floor((Date.now() - new Date(timestamp).getTime()) / 60000);
	});

	const nextUpdateMinutes = $derived.by(() => {
		if (minutesSinceGenerated === null) return '—';
		return Math.max(0, 10 - minutesSinceGenerated);
	});
</script>

<section
	class="relative mt-4 overflow-hidden rounded-3xl border border-slate-200 bg-linear-to-br from-white via-brand-50/40 to-violet-50/40 p-8 shadow-xs dark:border-slate-800 dark:from-slate-900 dark:via-brand-950/20 dark:to-violet-950/20"
>
	<div class="relative flex flex-wrap items-start justify-between gap-6">
		<div>
			<p class="text-xs font-medium tracking-wide text-brand-600 uppercase dark:text-brand-400">
				Bluesky campaign
			</p>

			<h1
				class="mt-1 text-4xl font-black tracking-tight text-slate-900 sm:text-5xl dark:text-white"
			>
				{campaign?.name ?? 'Campaign'}
			</h1>

			<div
				class="mt-4 flex flex-wrap items-center gap-4 text-sm text-slate-600 dark:text-slate-400"
			>
				<span>{fmt(start)} → {fmt(end)}</span>

				<span class="inline-flex items-center gap-1.5">
					<span class="h-1.5 w-1.5 rounded-full {running ? 'bg-emerald-500' : 'bg-slate-400'}"
					></span>
					{running ? 'Active' : 'Ended'}
				</span>

				{#if variant === 'latest'}
					<span class="inline-flex items-center gap-1.5 text-brand-600 dark:text-brand-400">
						<span class="h-2 w-2 animate-pulse rounded-full bg-brand-500"></span>

						Next update in {nextUpdateMinutes} min
					</span>
				{/if}
			</div>
		</div>

		{#if sentiment}
			<div
				class="rounded-2xl border border-slate-200 bg-white p-5 shadow-xs dark:border-slate-800 dark:bg-slate-900"
			>
				<p class="text-xs font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400">
					{sentimentPanelLabel}
				</p>

				<div class="mt-3 flex items-end gap-3">
					<p class="text-4xl font-black text-slate-900 dark:text-white">
						{Math.round((sentiment.score ?? 0) * 100)}%
					</p>
					<span class="mb-1 rounded-full px-2.5 py-1 text-xs font-semibold {sentimentLabelClass}">
						{sentiment.label}
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

<section class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-3">
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
				<SentimentChart points={timeline} />
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

					<span class="text-slate-500 dark:text-slate-400">
						score {comment.score}
					</span>
				</div>
			</article>
		{:else}
			<p class="text-sm text-slate-500 dark:text-slate-400">No key comments selected yet.</p>
		{/each}
	</div>
</section>
