<script lang="ts">
	import type { PageProps } from './$types';

	import dayjs from 'dayjs';

	import { resolve } from '$app/paths';
	import { m } from '$lib/paraglide/messages';

	let { data }: PageProps = $props();

	type RawItem = {
		Hash: string;
		Sort?: string;
		Topics?: string[];
		Start?: string;
		End?: string;
	};

	const items = $derived((data.Items ?? []) as RawItem[]);

	function campaignName(i: RawItem) {
		return i.Sort ?? 'Untitled';
	}

	function topics(i: RawItem): string[] {
		return i.Topics ?? [];
	}

	function fmt(d?: string) {
		if (!d) return '-';

		const parsed = dayjs(d);
		if (!parsed.isValid()) return d;

		return parsed.toDate().toLocaleDateString(undefined, {
			month: 'short',
			day: 'numeric',
			year: 'numeric'
		});
	}

	function daysLeft(end?: string) {
		if (!end) return null;

		const parsed = dayjs(end);
		if (!parsed.isValid()) return null;

		const today = dayjs().startOf('day');
		return Math.round(parsed.diff(today, 'days'));
	}
</script>

<div class="flex-1">
	<div class="mx-auto max-w-6xl px-6 py-10 sm:px-10 sm:py-14">
		<!-- Header -->
		<div class="flex flex-wrap items-end justify-between gap-4">
			<div>
				<p class="text-sm font-medium text-brand-600 dark:text-brand-400">{m.list_eyebrow()}</p>
				<h1
					class="mt-1 text-3xl font-black tracking-tight text-slate-900 sm:text-4xl dark:text-white"
				>
					{m.list_title()}
				</h1>
				<p class="mt-2 text-slate-600 dark:text-slate-400">
					{items.length === 0 ? m.list_emptyLead() : m.list_summary({ count: items.length })}
				</p>
			</div>
			<a
				href={resolve('/create')}
				class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
			>
				<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
					<path
						fill-rule="evenodd"
						d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
						clip-rule="evenodd"
					/>
				</svg>
				{m.list_newCampaign()}
			</a>
		</div>

		<!-- Stats strip -->
		{#if items.length > 0}
			<div class="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
				<div
					class="rounded-2xl border border-slate-200 bg-white p-5 shadow-xs dark:border-slate-800 dark:bg-slate-900"
				>
					<p class="text-xs font-medium tracking-wide text-slate-500 uppercase dark:text-slate-400">
						{m.list_statCampaigns()}
					</p>
					<p class="mt-2 text-3xl font-black text-slate-900 dark:text-white">{items.length}</p>
				</div>
				<div
					class="rounded-2xl border border-slate-200 bg-white p-5 shadow-xs dark:border-slate-800 dark:bg-slate-900"
				>
					<p class="text-xs font-medium tracking-wide text-slate-500 uppercase dark:text-slate-400">
						{m.list_statTopics()}
					</p>
					<p class="mt-2 text-3xl font-black text-slate-900 dark:text-white">
						{items.reduce((n, i) => n + topics(i).length, 0)}
					</p>
				</div>
				<div
					class="rounded-2xl border border-slate-200 bg-white p-5 shadow-xs dark:border-slate-800 dark:bg-slate-900"
				>
					<p class="text-xs font-medium tracking-wide text-slate-500 uppercase dark:text-slate-400">
						{m.list_statRunning()}
					</p>
					<p class="mt-2 text-3xl font-black text-slate-900 dark:text-white">
						{items.filter((i) => {
							const d = daysLeft(i.End);
							return d !== null && d >= 0;
						}).length}
					</p>
				</div>
			</div>
		{/if}

		<!-- Grid / Empty state -->
		{#if items.length === 0}
			<div
				class="mt-10 flex flex-col items-center justify-center rounded-3xl border-2 border-dashed border-slate-200 bg-white px-6 py-20 text-center dark:border-slate-800 dark:bg-slate-900"
			>
				<div
					class="flex h-16 w-16 items-center justify-center rounded-2xl bg-linear-to-br from-brand-100 to-violet-100 dark:from-brand-950/60 dark:to-violet-950/60"
				>
					<svg
						class="h-8 w-8 text-brand-600 dark:text-brand-400"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
					>
						<path d="M3 3v18h18" />
						<path d="M7 14l4-4 4 4 5-5" />
					</svg>
				</div>
				<h2 class="mt-6 text-xl font-bold text-slate-900 dark:text-white">
					{m.list_emptyTitle()}
				</h2>
				<p class="mt-2 max-w-sm text-sm text-slate-600 dark:text-slate-400">
					{m.list_emptyBody()}
				</p>
				<a
					href={resolve('/create')}
					class="mt-6 inline-flex items-center gap-2 rounded-xl bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-brand-600/30 transition hover:bg-brand-700 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:bg-brand-500 dark:hover:bg-brand-400"
				>
					{m.list_emptyCta()}
				</a>
			</div>
		{:else}
			<div class="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each items as item (`${item.Hash}::${campaignName(item)}`)}
					{@const name = campaignName(item)}
					{@const ts = topics(item)}
					{@const left = daysLeft(item.End)}
					{@const running = left !== null && left >= 0}
					<a
						href={resolve('/list/[campaign]', { campaign: name })}
						class="group relative flex flex-col rounded-2xl border border-slate-200 bg-white p-5 shadow-xs transition hover:-translate-y-0.5 hover:border-brand-300 hover:shadow-lg hover:shadow-brand-500/10 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:border-slate-800 dark:bg-slate-900 dark:hover:border-brand-700 dark:hover:shadow-brand-500/5"
					>
						<div class="flex items-start justify-between gap-2">
							<div class="min-w-0">
								<h3
									class="truncate text-lg font-bold text-slate-900 group-hover:text-brand-700 dark:text-white dark:group-hover:text-brand-300"
								>
									{name}
								</h3>
								<p class="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
									{fmt(item.Start)} → {fmt(item.End)}
								</p>
							</div>
							<span
								class="shrink-0 rounded-full px-2 py-0.5 text-xs font-medium {running
									? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300'
									: 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'}"
							>
								{running ? m.list_badgeDaysLeft({ days: left ?? 0 }) : m.list_badgeEnded()}
							</span>
						</div>

						{#if ts.length > 0}
							<div class="mt-4 flex flex-wrap gap-1.5">
								{#each ts.slice(0, 5) as tag (tag)}
									<span
										class="rounded-md bg-brand-50 px-2 py-0.5 text-xs font-medium text-brand-700 dark:bg-brand-950/50 dark:text-brand-300"
									>
										{tag}
									</span>
								{/each}
								{#if ts.length > 5}
									<span
										class="rounded-md bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600 dark:bg-slate-800 dark:text-slate-400"
									>
										+{ts.length - 5}
									</span>
								{/if}
							</div>
						{/if}

						<div
							class="mt-5 flex items-center justify-between border-t border-slate-100 pt-4 text-xs text-slate-500 dark:border-slate-800 dark:text-slate-400"
						>
							<span>{m.list_topicCount({ count: ts.length })}</span>
							<span
								class="font-medium text-brand-600 opacity-0 transition group-hover:opacity-100 dark:text-brand-400"
							>
								{m.common_view()} →
							</span>
						</div>
					</a>
				{/each}
			</div>
		{/if}
	</div>
</div>
