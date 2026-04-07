<script lang="ts">
	import { locale, supportedLocales, type Locale } from '$lib/i18n';

	const labels: Record<Locale, string> = { en: 'EN', es: 'ES' };
	const full: Record<Locale, string> = { en: 'English', es: 'Español' };
</script>

<div
	role="group"
	aria-label="Language"
	class="inline-flex items-center gap-0.5 rounded-lg border border-slate-200 bg-white p-0.5 text-xs font-semibold shadow-xs dark:border-slate-700 dark:bg-slate-900"
>
	{#each supportedLocales as loc (loc)}
		<button
			type="button"
			onclick={() => locale.set(loc)}
			aria-label="Switch to {full[loc]}"
			aria-pressed={$locale === loc}
			class="rounded-md px-2 py-1 transition focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none {$locale ===
			loc
				? 'bg-slate-900 text-white hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200'
				: 'text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-white'}"
		>
			{labels[loc]}
		</button>
	{/each}
</div>
