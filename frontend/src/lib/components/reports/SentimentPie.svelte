<script lang="ts">
	import { onMount } from 'svelte';
	import {
		Chart,
		DoughnutController,
		ArcElement,
		Tooltip,
		Legend
	} from 'chart.js';
	import { NEUTRAL_THRESHOLD } from '$lib/components/SentimentPill.svelte';
	import { m } from '$lib/paraglide/messages';

	Chart.register(DoughnutController, ArcElement, Tooltip, Legend);

	let {
		comments
	}: {
		comments: Array<{ score: number }>;
	} = $props();

	const counts = $derived.by(() => {
		let positive = 0;
		let neutral = 0;
		let negative = 0;
		for (const c of comments) {
			if (c.score >= NEUTRAL_THRESHOLD) positive++;
			else if (c.score <= -NEUTRAL_THRESHOLD) negative++;
			else neutral++;
		}
		return { positive, neutral, negative };
	});

	const total = $derived(counts.positive + counts.neutral + counts.negative);

	let canvas: HTMLCanvasElement;
	let chart: Chart | null = null;

	const labels = $derived([
		m.sentiment_pieLegendPositive(),
		m.sentiment_pieLegendNeutral(),
		m.sentiment_pieLegendNegative()
	]);

	onMount(() => {
		const ctx = canvas.getContext('2d');
		if (!ctx) return;

		chart = new Chart(ctx, {
			type: 'doughnut',
			data: {
				labels,
				datasets: [
					{
						data: [counts.positive, counts.neutral, counts.negative],
						backgroundColor: ['#10b981', '#f59e0b', '#f43f5e'],
						borderColor: ['#059669', '#d97706', '#e11d48'],
						borderWidth: 1
					}
				]
			},
			options: {
				responsive: true,
				maintainAspectRatio: false,
				cutout: '60%',
				plugins: {
					legend: {
						position: 'bottom',
						labels: {
							boxWidth: 12,
							padding: 12
						}
					},
					tooltip: {
						callbacks: {
							label: (item) => {
								const value = item.parsed as number;
								const pct = total > 0 ? Math.round((value / total) * 100) : 0;
								return `${item.label}: ${value} (${pct}%)`;
							}
						}
					}
				}
			}
		});

		return () => chart?.destroy();
	});

	$effect(() => {
		if (!chart) return;
		chart.data.labels = labels;
		chart.data.datasets[0].data = [counts.positive, counts.neutral, counts.negative];
		chart.update();
	});
</script>

{#if total === 0}
	<p class="text-sm text-slate-500 dark:text-slate-400">{m.sentiment_pieEmpty()}</p>
{:else}
	<div class="h-64">
		<canvas bind:this={canvas}></canvas>
	</div>
{/if}
