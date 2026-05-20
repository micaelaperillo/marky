<script lang="ts">
	import { formConfig } from '$lib/config';

	let {
		initialStart = '',
		initialEnd = '',
		onApply,
		onReset
	}: {
		initialStart?: string;
		initialEnd?: string;
		onApply: (range: { start: string; end: string }) => void;
		onReset?: () => void;
	} = $props();

	let start = $state('');
	let end = $state('');

	$effect(() => {
		start = initialStart;
	});

	$effect(() => {
		end = initialEnd;
	});

	const maxDays = formConfig.range.maxDays;

	const rangeError = $derived.by(() => {
		if (!start || !end) return null;
		const s = new Date(start);
		const e = new Date(end);
		if (Number.isNaN(s.getTime()) || Number.isNaN(e.getTime())) return 'Invalid dates.';
		if (e < s) return 'End date must be on or after start date.';
		const diffDays = (e.getTime() - s.getTime()) / (24 * 60 * 60 * 1000);
		if (diffDays > maxDays) return `Range cannot exceed ${maxDays} days.`;
		return null;
	});

	const canApply = $derived(!!start && !!end && !rangeError);

	function apply(event: Event) {
		event.preventDefault();
		if (!canApply) return;
		onApply({
			start: `${start}T00:00:00.000Z`,
			end: `${end}T23:59:59.999Z`
		});
	}

	function reset() {
		start = '';
		end = '';
		onReset?.();
	}
</script>

<form
	class="flex flex-wrap items-end gap-4 rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900"
	onsubmit={apply}
>
	<div class="flex flex-col">
		<label
			for="range-start"
			class="text-xs font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400"
		>
			Start date
		</label>
		<input
			id="range-start"
			type="date"
			bind:value={start}
			class="mt-1 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
		/>
	</div>

	<div class="flex flex-col">
		<label
			for="range-end"
			class="text-xs font-semibold tracking-wide text-slate-500 uppercase dark:text-slate-400"
		>
			End date
		</label>
		<input
			id="range-end"
			type="date"
			bind:value={end}
			class="mt-1 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
		/>
	</div>

	<button
		type="submit"
		disabled={!canApply}
		class="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white shadow-xs transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200 dark:disabled:bg-slate-700 dark:disabled:text-slate-400"
	>
		Apply
	</button>

	{#if initialStart || initialEnd}
		<button
			type="button"
			onclick={reset}
			class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
		>
			Reset
		</button>
	{/if}

	{#if rangeError}
		<p class="basis-full text-sm text-rose-600 dark:text-rose-400">{rangeError}</p>
	{:else}
		<p class="basis-full text-xs text-slate-500 dark:text-slate-400">
			Max range: {maxDays} days.
		</p>
	{/if}
</form>
