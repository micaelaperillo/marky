<script lang="ts">
	import { resolve } from '$app/paths';

	type Props = { size?: 'sm' | 'md' };
	let { size = 'md' }: Props = $props();

	const box = $derived(size === 'sm' ? 'h-8 w-8 text-base' : 'h-9 w-9 text-lg');
	const label = $derived(size === 'sm' ? 'text-lg' : 'text-xl');
</script>

<a
	href={resolve('/')}
	class="group inline-flex items-center gap-2 rounded-lg outline-none focus-visible:ring-2 focus-visible:ring-brand-500/40"
	aria-label="Marky — home"
>
	<span
		class="flex {box} items-center justify-center rounded-xl bg-linear-to-br from-brand-500 to-violet-600 font-black text-white shadow-md shadow-brand-500/30 transition group-hover:shadow-lg group-hover:shadow-brand-500/40"
	>
		M
	</span>
	<span class="{label} font-bold tracking-tight text-slate-900 dark:text-white">Marky</span>
</a>
