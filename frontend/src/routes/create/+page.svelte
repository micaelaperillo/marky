<script lang="ts">
	import { resolve } from '$app/paths';
	import { t } from '$lib/i18n';
	import { formConfig } from '$lib/config';

	type ErrorState = { key: string; vars?: Record<string, string | number> } | null;

	const { campaign: campaignCfg, topics: topicsCfg, range: rangeCfg } = formConfig;
	const MAX_TOPICS = topicsCfg.max;
	const MIN_LEN = topicsCfg.topic.minLength;
	const MAX_LEN = topicsCfg.topic.maxLength;

	let topics = $state<string[]>([]);
	let pending = $state('');
	let errorState = $state<ErrorState>(null);
	const errorMsg = $derived(errorState ? $t(errorState.key, errorState.vars) : '');

	function commit(raw: string) {
		const value = raw.trim().slice(0, MAX_LEN);
		if (!value) return;
		if (value.length < MIN_LEN) {
			errorState = {
				key: 'create.errorMinLen',
				vars: { minLen: MIN_LEN, plural: MIN_LEN === 1 ? '' : 's' }
			};
			return;
		}
		if (topics.includes(value)) {
			errorState = { key: 'create.errorDuplicate', vars: { topic: value } };
			return;
		}
		if (topics.length >= MAX_TOPICS) {
			errorState = { key: 'create.errorMax', vars: { max: MAX_TOPICS } };
			return;
		}
		topics = [...topics, value];
		errorState = null;
	}

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter' || e.key === ',') {
			e.preventDefault();
			commit(pending);
			pending = '';
		} else if (e.key === 'Backspace' && pending === '' && topics.length > 0) {
			topics = topics.slice(0, -1);
			errorState = null;
		}
	}

	function onPaste(e: ClipboardEvent) {
		const text = e.clipboardData?.getData('text') ?? '';
		if (!text.includes(',') && !text.includes('\n')) return;
		e.preventDefault();
		text
			.split(/[,\n]/)
			.map((s) => s.trim())
			.filter(Boolean)
			.forEach(commit);
		pending = '';
	}

	function remove(i: number) {
		topics = topics.filter((_, idx) => idx !== i);
		errorState = null;
	}

	function flushPending() {
		if (pending.trim()) {
			commit(pending);
			pending = '';
		}
	}
</script>

<div class="flex-1">
	<div class="mx-auto max-w-3xl px-6 py-10 sm:py-14">
		<nav class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
			<a href={resolve('/list')} class="hover:text-slate-900 dark:hover:text-white">
				{$t('create.breadcrumbCampaigns')}
			</a>
			<span>/</span>
			<span class="font-medium text-slate-900 dark:text-white">{$t('create.breadcrumbNew')}</span>
		</nav>

		<header class="mt-4">
			<h1 class="text-3xl font-black tracking-tight text-slate-900 sm:text-4xl dark:text-white">
				{$t('create.title')}
			</h1>
			<p class="mt-2 text-slate-600 dark:text-slate-400">{$t('create.subtitle')}</p>
		</header>

		<form
			method="post"
			onsubmit={flushPending}
			class="mt-8 space-y-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-xs sm:p-8 dark:border-slate-800 dark:bg-slate-900"
		>
			<!-- Name -->
			<div>
				<label for="campaign" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
					{$t('create.nameLabel')}
				</label>
				<p class="mt-1 text-xs text-slate-500 dark:text-slate-400">
					{$t('create.nameHint', { max: campaignCfg.maxLength })}
				</p>
				<input
					type="text"
					name="campaign"
					id="campaign"
					required
					minlength={campaignCfg.minLength}
					maxlength={campaignCfg.maxLength}
					pattern={campaignCfg.patternHtml}
					placeholder={campaignCfg.placeholder}
					class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500 dark:[color-scheme:dark]"
				/>
			</div>

			<!-- Topics (tag input) -->
			<div>
				<label for="topic-input" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
					{$t('create.topicsLabel')}
				</label>
				<p class="mt-1 text-xs text-slate-500 dark:text-slate-400">
					{$t('create.topicsHint', { max: MAX_TOPICS, minLen: MIN_LEN, maxLen: MAX_LEN })}
				</p>

				<!-- Hidden inputs to keep form action working unchanged -->
				{#each topics as topic (topic)}
					<input type="hidden" name="topic" value={topic} />
				{/each}

				<label
					for="topic-input"
					class="mt-2 flex w-full cursor-text flex-wrap items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-2 py-2 text-left shadow-xs transition focus-within:border-brand-500 focus-within:ring-2 focus-within:ring-brand-500/20 dark:border-slate-700 dark:bg-slate-950"
				>
					{#each topics as topic, i (topic)}
						<span
							class="group inline-flex items-center gap-1 rounded-md bg-brand-50 py-1 pr-1 pl-2 text-xs font-semibold text-brand-700 ring-1 ring-brand-200 ring-inset dark:bg-brand-950/50 dark:text-brand-300 dark:ring-brand-900"
						>
							{topic}
							<button
								type="button"
								onclick={(e) => {
									e.stopPropagation();
									remove(i);
								}}
								aria-label={$t('create.removeTopic', { topic })}
								class="flex h-4 w-4 items-center justify-center rounded text-brand-500 transition hover:bg-brand-200 hover:text-brand-800 dark:text-brand-400 dark:hover:bg-brand-900 dark:hover:text-brand-100"
							>
								<svg class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
									<path
										fill-rule="evenodd"
										d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
										clip-rule="evenodd"
									/>
								</svg>
							</button>
						</span>
					{/each}
					<input
						bind:value={pending}
						onkeydown={onKeydown}
						onpaste={onPaste}
						onblur={flushPending}
						id="topic-input"
						type="text"
						maxlength={MAX_LEN}
						placeholder={topics.length === 0 ? $t('create.topicPlaceholder') : ''}
						required={topics.length === 0}
						class="min-w-[8rem] flex-1 border-0 bg-transparent px-1.5 py-0.5 text-sm text-slate-900 placeholder:text-slate-400 focus:ring-0 focus:outline-none dark:text-slate-100 dark:placeholder:text-slate-500"
					/>
				</label>

				<div class="mt-1.5 flex items-center justify-between text-xs">
					<span role="alert" aria-live="polite" class="text-rose-600 dark:text-rose-400">
						{errorMsg}
					</span>
					<span class="text-slate-400 dark:text-slate-500">
						{$t('create.topicCounter', { count: topics.length, max: MAX_TOPICS })}
					</span>
				</div>
			</div>

			<!-- Dates -->
			<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
				<div>
					<label for="start" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{$t('create.startLabel')}
					</label>
					<input
						type="date"
						name="start"
						id="start"
						required
						class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:[color-scheme:dark]"
					/>
				</div>
				<div>
					<label for="end" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{$t('create.endLabel')}
					</label>
					<input
						type="date"
						name="end"
						id="end"
						required
						class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:[color-scheme:dark]"
					/>
				</div>
			</div>
			<p class="text-xs text-slate-500 dark:text-slate-400">
				{$t('create.intervalHint', { max: rangeCfg.maxDays })}
			</p>

			<!-- Actions -->
			<div
				class="flex items-center justify-end gap-3 border-t border-slate-100 pt-6 dark:border-slate-800"
			>
				<a
					href={resolve('/list')}
					class="rounded-lg px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
				>
					{$t('common.cancel')}
				</a>
				<button
					type="submit"
					class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
				>
					{$t('create.submit')}
				</button>
			</div>
		</form>
	</div>
</div>
