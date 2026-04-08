<script lang="ts">
	import { type Locale, locales, setLocale, getLocale } from '$lib/paraglide/runtime';

	const labels: Record<Locale, string> = { en: 'EN', es: 'ES' };
	const full: Record<Locale, string> = { en: 'English', es: 'Español' };

	const current = $derived(getLocale());
</script>

<div
	role="group"
	aria-label="Language"
	class="inline-flex items-center gap-0.5 rounded-lg border border-slate-200 bg-white p-0.5 text-xs font-semibold shadow-xs dark:border-slate-700 dark:bg-slate-900"
>
	{#each locales as loc (loc)}
		{@const selected = current === loc}
		<button
			type="button"
			onclick={() => setLocale(loc)}
			aria-label="Switch to {full[loc]}"
			aria-pressed={selected}
			class={[
				'rounded-md px-2 py-1 transition focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none',
				{
					'bg-slate-900 text-white hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200':
						selected,
					'text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-white':
						!selected
				}
			]}
		>
			{labels[loc]}
		</button>
	{/each}
</div>
