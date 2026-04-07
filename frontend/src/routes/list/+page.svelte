<script lang="ts">
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

{#each data.Items as item (item.UserId.S! + item.Name.S!)}
	{JSON.stringify(item, null, 4)}
{/each}
