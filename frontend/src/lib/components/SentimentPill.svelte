<script lang="ts" module>
	import { m } from '$lib/paraglide/messages';

	export type SentimentBandKey =
		| 'very-neg'
		| 'reas-neg'
		| 'slight-neg'
		| 'neutral'
		| 'slight-pos'
		| 'reas-pos'
		| 'very-pos';

	export type SentimentBand = {
		key: SentimentBandKey;
		label: string;
		classes: string;
	};

	export const NEUTRAL_THRESHOLD = 0.14;

	export function bandFromScore(score: number): SentimentBand {
		if (score <= -0.71)
			return {
				key: 'very-neg',
				label: m.sentiment_veryNegative(),
				classes:
					'bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-200'
			};
		if (score <= -0.43)
			return {
				key: 'reas-neg',
				label: m.sentiment_reasonablyNegative(),
				classes:
					'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300'
			};
		if (score <= -NEUTRAL_THRESHOLD)
			return {
				key: 'slight-neg',
				label: m.sentiment_slightlyNegative(),
				classes:
					'bg-orange-50 text-orange-700 dark:bg-orange-950/40 dark:text-orange-300'
			};
		if (score < NEUTRAL_THRESHOLD)
			return {
				key: 'neutral',
				label: m.sentiment_neutral(),
				classes:
					'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300'
			};
		if (score < 0.43)
			return {
				key: 'slight-pos',
				label: m.sentiment_slightlyPositive(),
				classes:
					'bg-lime-50 text-lime-700 dark:bg-lime-950/40 dark:text-lime-300'
			};
		if (score < 0.71)
			return {
				key: 'reas-pos',
				label: m.sentiment_reasonablyPositive(),
				classes:
					'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
			};
		return {
			key: 'very-pos',
			label: m.sentiment_veryPositive(),
			classes:
				'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-200'
		};
	}
</script>

<script lang="ts">
	let { score, size = 'md' }: { score: number; size?: 'sm' | 'md' } = $props();
	const band = $derived(bandFromScore(score));
	const sizeClass = $derived(
		size === 'sm' ? 'px-2 py-0.5 text-[10px]' : 'px-2.5 py-1 text-xs'
	);
</script>

<span
	class="inline-flex items-center rounded-full font-semibold {sizeClass} {band.classes}"
	title="score {score.toFixed(2)}"
>
	{band.label}
</span>
