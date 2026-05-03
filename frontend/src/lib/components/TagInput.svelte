<script lang="ts">
	import { m } from '$lib/paraglide/messages';

	interface Props {
		topics: string[];
		maxTopics: number;
		minLength: number;
		maxLength: number;
		hintId?: string;
	}

	type ErrorKey = 'create_errorMinLen' | 'create_errorDuplicate' | 'create_errorMax';
	type ErrorState = { key: ErrorKey; vars?: Record<string, string | number> } | null;

	let { topics = $bindable(), maxTopics, minLength, maxLength, hintId }: Props = $props();
	let pending = $state('');
	let errorState = $state<ErrorState>(null);
	const errorMsg = $derived(errorState ? m[errorState.key](errorState.vars as never) : '');

	function commit(raw: string) {
		const value = raw.trim().slice(0, maxLength);
		if (!value) return;
		if (value.length < minLength) {
			errorState = { key: 'create_errorMinLen', vars: { minLen: minLength } };
			return;
		}
		if (topics.includes(value)) {
			errorState = { key: 'create_errorDuplicate', vars: { topic: value } };
			return;
		}
		if (topics.length >= maxTopics) {
			errorState = { key: 'create_errorMax', vars: { max: maxTopics } };
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

	export function flush() {
		if (pending.trim()) {
			commit(pending);
			pending = '';
		}
	}
</script>

<div
	class="mt-2 flex w-full cursor-text flex-wrap items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-2 py-2 text-left shadow-xs transition focus-within:border-brand-500 focus-within:ring-2 focus-within:ring-brand-500/20 dark:border-slate-700 dark:bg-slate-950"
>
	{#each topics as topic, i (topic)}
		<span
			class="group inline-flex items-center gap-1 rounded-md bg-brand-50 py-1 pr-1 pl-2 text-xs font-semibold text-brand-700 ring-1 ring-brand-200 ring-inset dark:bg-brand-950/50 dark:text-brand-300 dark:ring-brand-900"
		>
			{topic}
			<button
				type="button"
				onclick={() => remove(i)}
				aria-label={m.create_removeTopic({ topic })}
				class="-m-1 rounded p-2 text-brand-400 transition hover:bg-brand-100 hover:text-brand-700 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none dark:text-brand-500 dark:hover:bg-brand-900 dark:hover:text-brand-200"
			>
				<svg class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
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
		onblur={() => flush()}
		id="topic-input"
		type="text"
		aria-describedby={hintId}
		maxlength={maxLength}
		placeholder={topics.length === 0 ? m.create_topicPlaceholder() : ''}
		required={topics.length === 0}
		class="min-w-32 flex-1 border-0 bg-transparent px-1.5 py-0.5 text-sm text-slate-900 placeholder:text-slate-400 focus:ring-0 focus:outline-none dark:text-slate-100 dark:placeholder:text-slate-500"
	/>
</div>

<div class="mt-2 flex items-center justify-between">
	{#if errorMsg}
		<span
			role="alert"
			aria-live="polite"
			class="text-xs font-medium text-rose-600 dark:text-rose-400"
		>
			{errorMsg}
		</span>
	{:else}
		<span></span>
	{/if}
	<span class="text-xs text-slate-400 dark:text-slate-500">
		{m.create_topicCounter({ count: topics.length, max: maxTopics })}
	</span>
</div>
