<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { apiFetch } from '$lib/api';
	import TagInput from '$lib/components/TagInput.svelte';
	import { formConfig } from '$lib/config';
	import { m } from '$lib/paraglide/messages';

	const { campaign: campaignCfg, topics: topicsCfg, range: rangeCfg } = formConfig;
	const MAX_TOPICS = topicsCfg.max;
	const MIN_LEN = topicsCfg.topic.minLength;
	const MAX_LEN = topicsCfg.topic.maxLength;

	let topics = $state<string[]>([]);
	let formError = $state('');
	let nameError = $state('');
	let startError = $state('');
	let endError = $state('');
	let topicsError = $state('');
	let frequencyMin = $state(60);
	let submitting = $state(false);
	let tagInput!: TagInput;

	function clearErrors() {
		formError = '';
		nameError = '';
		startError = '';
		endError = '';
		topicsError = '';
	}

	function toLocalDatetime(date: Date) {
		const offset = date.getTimezoneOffset();
		const localDate = new Date(date.getTime() - offset * 60 * 1000);
		return localDate.toISOString().slice(0, 16);
	}

	function validateClient(startIso: string, endIso: string, campaign: string): boolean {
		clearErrors();
		let ok = true;

		if (!campaign) {
			nameError = m.create_errorNameLength({
				min: campaignCfg.minLength,
				max: campaignCfg.maxLength
			});
			ok = false;
		} else if (
			campaign.length < campaignCfg.minLength ||
			campaign.length > campaignCfg.maxLength
		) {
			nameError = m.create_errorNameLength({
				min: campaignCfg.minLength,
				max: campaignCfg.maxLength
			});
			ok = false;
		}

		const startMs = startIso ? Date.parse(startIso) : NaN;
		const endMs = endIso ? Date.parse(endIso) : NaN;
		const now = Date.now();
		const minFutureMs = 2 * 60 * 1000;

		if (!startIso || Number.isNaN(startMs)) {
			startError = m.create_errorStartPast();
			ok = false;
		} else if (startMs < now + minFutureMs) {
			startError = m.create_errorStartPast();
			ok = false;
		}

		if (!endIso || Number.isNaN(endMs)) {
			endError = m.create_errorEndBeforeStart();
			ok = false;
		} else if (!Number.isNaN(startMs) && endMs <= startMs) {
			endError = m.create_errorEndBeforeStart();
			ok = false;
		} else if (!Number.isNaN(startMs)) {
			const diffDays = (endMs - startMs) / 86_400_000;
			if (diffDays > rangeCfg.maxDays) {
				endError = m.create_errorRangeTooLong({ max: rangeCfg.maxDays });
				ok = false;
			}
		}

		if (topics.length === 0) {
			topicsError = m.create_errorTopicsRequired();
			ok = false;
		}

		return ok;
	}

	function applyServerIssues(issues: Array<{ path: (string | number)[]; message: string }>) {
		clearErrors();
		let unmapped = '';
		for (const issue of issues) {
			const field = String(issue.path?.[0] ?? '');
			switch (field) {
				case 'campaign':
					nameError ||= issue.message;
					break;
				case 'start':
					startError ||= issue.message;
					break;
				case 'end':
					endError ||= issue.message;
					break;
				case 'topics':
					topicsError ||= issue.message;
					break;
				default:
					unmapped ||= issue.message;
			}
		}
		if (unmapped) formError = unmapped;
	}

	async function handleSubmit(e: SubmitEvent) {
		e.preventDefault();
		tagInput.flush();

		const form = e.currentTarget as HTMLFormElement;
		const fd = new FormData(form);
		const campaign = ((fd.get('campaign') as string) ?? '').trim();
		const rawStart = (fd.get('start') as string) ?? '';
		const rawEnd = (fd.get('end') as string) ?? '';
		const start = rawStart ? new Date(rawStart).toISOString() : '';
		const end = rawEnd ? new Date(rawEnd).toISOString() : '';

		if (!validateClient(start, end, campaign)) return;

		submitting = true;
		try {
			const res = await apiFetch('/campaigns', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ campaign, start, end, topics, frequencyMin })
			});
			if (res.ok) {
				goto(resolve('/list'));
				return;
			}
			const body = await res.json().catch(() => ({}));
			if (Array.isArray(body?.issues) && body.issues.length > 0) {
				applyServerIssues(body.issues);
			} else {
				formError = body?.error ?? m.create_errorUnknown();
			}
		} catch {
			formError = m.create_errorNetwork();
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
			novalidate
			class="mt-8 space-y-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-xs sm:p-8 dark:border-slate-800 dark:bg-slate-900"
		>
			{#if formError}
				<div
					role="alert"
					aria-live="assertive"
					class="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 dark:border-rose-900/50 dark:bg-rose-950/30 dark:text-rose-300"
				>
					{formError}
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
					aria-describedby={nameError ? 'campaign-error' : 'campaign-hint'}
					aria-invalid={nameError ? 'true' : undefined}
					minlength={campaignCfg.minLength}
					maxlength={campaignCfg.maxLength}
					placeholder="Product launch"
					class="mt-2 block w-full rounded-lg border bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:ring-2 focus:outline-none dark:bg-slate-950 dark:text-slate-100 dark:scheme-dark dark:placeholder:text-slate-500 {nameError
						? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500/20 dark:border-rose-700'
						: 'border-slate-300 focus:border-brand-500 focus:ring-brand-500/20 dark:border-slate-700'}"
				/>
				{#if nameError}
					<p id="campaign-error" class="mt-1 text-xs text-rose-600 dark:text-rose-400">
						{nameError}
					</p>
				{/if}
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
				{#if topicsError}
					<p class="mt-1 text-xs text-rose-600 dark:text-rose-400">{topicsError}</p>
				{/if}
			</div>

			<!-- Dates -->
			<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
				<div>
					<label for="start" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{m.create_startLabel()}
					</label>
					<input
						type="datetime-local"
						name="start"
						id="start"
						required
						aria-invalid={startError ? 'true' : undefined}
						aria-describedby={startError ? 'start-error' : undefined}
						value={toLocalDatetime(new Date())}
						class="mt-2 block w-full rounded-lg border bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition focus:ring-2 focus:outline-none dark:bg-slate-950 dark:text-slate-100 dark:scheme-dark {startError
							? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500/20 dark:border-rose-700'
							: 'border-slate-300 focus:border-brand-500 focus:ring-brand-500/20 dark:border-slate-700'}"
					/>
					{#if startError}
						<p id="start-error" class="mt-1 text-xs text-rose-600 dark:text-rose-400">
							{startError}
						</p>
					{/if}
				</div>
				<div>
					<label for="end" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{m.create_endLabel()}
					</label>
					<input
						type="datetime-local"
						name="end"
						id="end"
						required
						aria-invalid={endError ? 'true' : undefined}
						aria-describedby={endError ? 'end-error' : undefined}
						class="mt-2 block w-full rounded-lg border bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition focus:ring-2 focus:outline-none dark:bg-slate-950 dark:text-slate-100 dark:scheme-dark {endError
							? 'border-rose-400 focus:border-rose-500 focus:ring-rose-500/20 dark:border-rose-700'
							: 'border-slate-300 focus:border-brand-500 focus:ring-brand-500/20 dark:border-slate-700'}"
					/>
					{#if endError}
						<p id="end-error" class="mt-1 text-xs text-rose-600 dark:text-rose-400">
							{endError}
						</p>
					{/if}
				</div>
			</div>

			<!-- Frequency -->
			<div>
				<label
					for="frequencyMin"
					class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
				>
					Report frequency: <span class="text-brand-600 dark:text-brand-400">{frequencyMin} minutes</span>
				</label>
				<input
					type="range"
					id="frequencyMin"
					min="5"
					max="60"
					step="5"
					bind:value={frequencyMin}
					class="mt-4 h-2 w-full cursor-pointer appearance-none rounded-lg bg-slate-200 dark:bg-slate-700"
				/>
				<div class="mt-2 flex justify-between text-xs text-slate-500 dark:text-slate-400">
					<span>5m</span>
					<span>15m</span>
					<span>30m</span>
					<span>45m</span>
					<span>60m</span>
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
