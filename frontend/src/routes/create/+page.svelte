<script lang="ts">
	import { goto } from '$app/navigation';
	import { base, resolve } from '$app/paths';
	import TagInput from '$lib/components/TagInput.svelte';
	import { formConfig } from '$lib/config';
	import { m } from '$lib/paraglide/messages';

	const { campaign: campaignCfg, topics: topicsCfg, range: rangeCfg } = formConfig;
	const MAX_TOPICS = topicsCfg.max;
	const MIN_LEN = topicsCfg.topic.minLength;
	const MAX_LEN = topicsCfg.topic.maxLength;

	let topics = $state<string[]>([]);
	let apiError = $state('');
	let submitting = $state(false);
	let tagInput!: TagInput;

	async function handleSubmit(e: SubmitEvent) {
		e.preventDefault();
		tagInput.flush();

		const form = e.currentTarget as HTMLFormElement;
		const fd = new FormData(form);
		const campaign = fd.get('campaign') as string;
		const start = fd.get('start') as string;
		const end = fd.get('end') as string;

		if (!campaign || !start || !end || topics.length === 0) return;

		apiError = '';
		submitting = true;
		try {
			const res = await fetch(`${base}/api/campaigns`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ campaign, start, end, topics })
			});
			if (res.ok) {
				goto(`${base}/list`);
			} else {
				const body = await res.json().catch(() => ({ error: m.create_errorUnknown() }));
				apiError = body.error || m.create_errorUnknown();
			}
		} catch {
			apiError = m.create_errorNetwork();
		} finally {
			submitting = false;
		}
	}
</script>

<div class="flex-1">
	<div class="mx-auto max-w-3xl px-6 py-10 sm:py-14">
		<nav
			aria-label="Breadcrumb"
			class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400"
		>
			<a
				href={resolve('/list')}
				class="-mx-1 rounded px-1 py-2 hover:text-slate-900 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:hover:text-white"
			>
				{m.create_breadcrumbCampaigns()}
			</a>
			<span>/</span>
			<span class="font-medium text-slate-900 dark:text-white">{m.create_breadcrumbNew()}</span>
		</nav>

		<header class="mt-4">
			<h1 class="text-3xl font-black tracking-tight text-slate-900 sm:text-4xl dark:text-white">
				{m.create_title()}
			</h1>
			<p class="mt-2 text-slate-600 dark:text-slate-400">{m.create_subtitle()}</p>
		</header>

		<form
			onsubmit={handleSubmit}
			class="mt-8 space-y-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-xs sm:p-8 dark:border-slate-800 dark:bg-slate-900"
		>
			{#if apiError}
				<div
					role="alert"
					aria-live="assertive"
					class="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 dark:border-rose-900/50 dark:bg-rose-950/30 dark:text-rose-300"
				>
					{apiError}
				</div>
			{/if}

			<!-- Name -->
			<div>
				<label
					for="campaign"
					class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
				>
					{m.create_nameLabel()}
				</label>
				<p id="campaign-hint" class="mt-1 text-xs text-slate-500 dark:text-slate-400">
					{m.create_nameHint({ max: campaignCfg.maxLength })}
				</p>
				<input
					type="text"
					name="campaign"
					id="campaign"
					required
					aria-required="true"
					aria-describedby="campaign-hint"
					minlength={campaignCfg.minLength}
					maxlength={campaignCfg.maxLength}
					pattern={campaignCfg.patternHtml}
					placeholder={campaignCfg.placeholder}
					class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:scheme-dark dark:placeholder:text-slate-500"
				/>
			</div>

			<!-- Topics (tag input) -->
			<div>
				<label
					for="topic-input"
					class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
				>
					{m.create_topicsLabel()}
				</label>
				<p id="topics-hint" class="mt-1 text-xs text-slate-500 dark:text-slate-400">
					{m.create_topicsHint({ max: MAX_TOPICS, minLen: MIN_LEN, maxLen: MAX_LEN })}
				</p>

				<TagInput
					bind:topics
					maxTopics={MAX_TOPICS}
					minLength={MIN_LEN}
					maxLength={MAX_LEN}
					hintId="topics-hint"
					bind:this={tagInput}
				/>
			</div>

			<!-- Dates -->
			<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
				<div>
					<label for="start" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{m.create_startLabel()}
					</label>
					<input
						type="date"
						name="start"
						id="start"
						required
						class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:scheme-dark"
					/>
				</div>
				<div>
					<label for="end" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{m.create_endLabel()}
					</label>
					<input
						type="date"
						name="end"
						id="end"
						required
						class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:scheme-dark"
					/>
				</div>
			</div>
			<p class="text-xs text-slate-500 dark:text-slate-400">
				{m.create_intervalHint({ max: rangeCfg.maxDays })}
			</p>

			<!-- Actions -->
			<div
				class="flex items-center justify-end gap-3 border-t border-slate-100 pt-6 dark:border-slate-800"
			>
				<a
					href={resolve('/list')}
					class="rounded-lg px-4 py-3 text-sm font-semibold text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
				>
					{m.common_cancel()}
				</a>
				<button
					type="submit"
					disabled={submitting}
					class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none disabled:opacity-50 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
				>
					{submitting ? m.create_submitting() : m.create_submit()}
				</button>
			</div>
		</form>
	</div>
</div>
