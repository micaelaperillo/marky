<script lang="ts">
	// import type { PageProps } from './$types';

	// let { data, form }: PageProps = $props();
</script>

<form method="post" class="flex flex-col">
	<label for="campaign">Campaign name</label>
	<input type="text" name="campaign" id="campaign" required />

	<input type="text" name="topic" id="topic" required />
	<input type="text" name="topic" id="topic" />
	<input type="text" name="topic" id="topic" />
	<input type="text" name="topic" id="topic" />
	<input type="text" name="topic" id="topic" />
	<input type="text" name="topic" id="topic" />

	<label for="start">Date start</label>
	<input type="date" name="start" id="start" required />

	<label for="end">Date end</label>
	<input type="date" name="end" id="end" required />

	<button type="submit">Send</button>
</form>
