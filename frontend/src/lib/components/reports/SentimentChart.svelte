<script lang="ts">
	import { onMount } from 'svelte';
	import {
		Chart,
		LineController,
		LineElement,
		PointElement,
		LinearScale,
		TimeScale,
		Filler,
		Tooltip,
		CategoryScale
	} from 'chart.js';

	Chart.register(LineController, LineElement, PointElement, LinearScale, TimeScale, Filler, Tooltip, CategoryScale);

	type Point = {
		timestamp: string;
		sentiment: number;
	};

	let {
		points = [],
		onPointClick
	}: {
		points: Point[];
		onPointClick?: (timestamp: string) => void;
	} = $props();

	let pointsDesc = $derived([...points].reverse());
	let canvas: HTMLCanvasElement;
	let chart: Chart | null = null;
	let hoverPointer = $state(false);

	onMount(() => {
		const ctx = canvas.getContext('2d');
		if (!ctx) return;

		chart = new Chart(ctx, {
			type: 'line',
			data: {
				labels: pointsDesc.map((p) =>
					new Intl.DateTimeFormat('es-AR', {
						day: '2-digit',
						hour: '2-digit',
						minute: '2-digit'
					}).format(new Date(p.timestamp))
				),
				datasets: [
					{
						label: 'Sentiment',
						data: pointsDesc.map((p) => p.sentiment),
						tension: 0.35,
						fill: true,
						borderWidth: 2,
						pointRadius: 3,
						pointHoverRadius: 6,
						borderColor: '#16a34a',
						backgroundColor: 'rgba(34, 197, 94, 0.18)'
					}
				]
			},
			options: {
				responsive: true,
				maintainAspectRatio: false,
				scales: {
					y: {
						min: -1,
						max: 1,
						grid: {
							color: '#e5e7eb'
						}
					},
					x: {
						grid: {
							display: false
						}
					}
				},
				plugins: {
					legend: {
						display: false
					}
				},
				onHover: (_evt, els) => {
					hoverPointer = !!onPointClick && els.length > 0;
				},
				onClick: (_evt, els) => {
					if (!onPointClick || els.length === 0) return;
					const idx = els[0].index;
					const point = pointsDesc[idx];
					if (point) onPointClick(point.timestamp);
				}
			}
		});

		return () => chart?.destroy();
	});

	$effect(() => {
		if (!chart) return;
		chart.data.labels = pointsDesc.map((p) =>
			new Intl.DateTimeFormat('es-AR', {
				day: '2-digit',
				hour: '2-digit',
				minute: '2-digit'
			}).format(new Date(p.timestamp))
		);
		chart.data.datasets[0].data = pointsDesc.map((p) => p.sentiment);
		chart.update();
	});
</script>

<div class="h-80" class:cursor-pointer={hoverPointer}>
	<canvas bind:this={canvas}></canvas>
</div>
