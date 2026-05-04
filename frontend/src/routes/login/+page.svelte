<script lang="ts">
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import { m } from '$lib/paraglide/messages';

	let submitting = $state(false);
	let loginError = $state('');

	async function handleSubmit(e: SubmitEvent) {
		e.preventDefault();
		const form = e.currentTarget as HTMLFormElement;
		const id = new FormData(form).get('id') as string;
		if (!id) return;

		loginError = '';
		submitting = true;
		try {
			const res = await fetch(`${base}/api/auth/login`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ id })
			});
			if (res.ok) {
				goto(`${base}/list`);
			} else {
				const body = await res.json().catch(() => ({ error: m.login_errorUnknown() }));
				loginError = body.error || m.login_errorUnknown();
			}
		} catch {
			loginError = m.login_errorNetwork();
		} finally {
			submitting = false;
		}
	}
</script>

<div class="relative isolate flex flex-1 items-center justify-center overflow-hidden px-6 py-16">
	<div
		class="absolute inset-0 -z-10 bg-linear-to-br from-brand-50 via-white to-violet-50 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950"
	></div>
	<div
		class="absolute -top-32 -left-32 -z-10 h-96 w-96 rounded-full bg-brand-200/40 blur-3xl dark:bg-brand-700/20"
	></div>
	<div
		class="absolute -right-32 -bottom-32 -z-10 h-96 w-96 rounded-full bg-violet-200/40 blur-3xl dark:bg-violet-700/20"
	></div>

	<div class="w-full max-w-md">
		<div
			class="rounded-2xl border border-slate-200 bg-white p-8 shadow-xl shadow-slate-900/5 dark:border-slate-800 dark:bg-slate-900 dark:shadow-black/30"
		>
			<h1 class="text-2xl font-black tracking-tight text-slate-900 dark:text-white">
				{m.login_title()}
			</h1>
			<p class="mt-1 text-sm text-slate-600 dark:text-slate-400">{m.login_subtitle()}</p>

			{#if loginError}
				<div
					role="alert"
					aria-live="assertive"
					class="mt-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 dark:border-rose-900 dark:bg-rose-950/50 dark:text-rose-300"
				>
					{loginError}
				</div>
			{/if}

			<form onsubmit={handleSubmit} class="mt-6 space-y-4">
				<div>
					<label for="id" class="block text-sm font-semibold text-slate-900 dark:text-slate-100">
						{m.login_userIdLabel()}
					</label>
					<input
						type="text"
						name="id"
						id="id"
						required
						aria-required="true"
						placeholder={m.login_userIdPlaceholder()}
						class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
					/>
				</div>
				<button
					type="submit"
					disabled={submitting}
					class="w-full rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none disabled:opacity-50 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
				>
					{submitting ? m.login_submitting() : m.login_submit()}
				</button>
			</form>
		</div>

		<p class="mt-6 text-center text-xs text-slate-500 dark:text-slate-400">{m.login_footer()}</p>
	</div>
</div>
