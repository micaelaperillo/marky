<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { forgotPassword, confirmForgotPassword } from '$lib/auth';
	import { m } from '$lib/paraglide/messages';

	let step = $state<'request' | 'confirm'>('request');
	let email = $state('');
	let code = $state('');
	let newPassword = $state('');
	let confirmPassword = $state('');
	let submitting = $state(false);
	let errorMsg = $state('');

	function mapError(err: unknown): string {
		if (!(err instanceof Error)) return m.login_errorUnknown();
		const errCode = (err as { code?: string }).code;
		switch (errCode) {
			case 'CodeMismatchException':
				return m.reset_errorInvalidCode();
			case 'ExpiredCodeException':
				return m.reset_errorExpiredCode();
			default:
				return err.message || m.login_errorUnknown();
		}
	}

	async function handleRequest(e: SubmitEvent) {
		e.preventDefault();
		if (!email) return;
		errorMsg = '';
		submitting = true;
		try {
			await forgotPassword(email);
			step = 'confirm';
		} catch (err) {
			errorMsg = mapError(err);
		} finally {
			submitting = false;
		}
	}

	async function handleConfirm(e: SubmitEvent) {
		e.preventDefault();
		if (!code || !newPassword) return;
		if (newPassword !== confirmPassword) {
			errorMsg = m.login_errorPasswordMismatch();
			return;
		}
		errorMsg = '';
		submitting = true;
		try {
			await confirmForgotPassword(email, code, newPassword);
			goto(resolve('/login'));
		} catch (err) {
			errorMsg = mapError(err);
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
				{step === 'confirm' ? m.reset_codeTitle() : m.reset_title()}
			</h1>
			<p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
				{step === 'confirm' ? m.reset_codeSubtitle() : m.reset_subtitle()}
			</p>

			{#if errorMsg}
				<div
					role="alert"
					aria-live="assertive"
					class="mt-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700 dark:border-rose-900 dark:bg-rose-950/50 dark:text-rose-300"
				>
					{errorMsg}
				</div>
			{/if}

			{#if step === 'request'}
				<form onsubmit={handleRequest} class="mt-6 space-y-4">
					<div>
						<label
							for="reset-email"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.reset_emailLabel()}
						</label>
						<input
							type="email"
							id="reset-email"
							required
							bind:value={email}
							placeholder={m.login_emailPlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<button
						type="submit"
						disabled={submitting}
						class="w-full rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none disabled:opacity-50 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
					>
						{submitting ? m.reset_emailSubmitting() : m.reset_emailSubmit()}
					</button>
					<a
						href={resolve('/login')}
						class="block text-center text-sm text-brand-600 hover:underline dark:text-brand-400"
					>
						{m.login_switchToSignin()}
					</a>
				</form>
			{:else}
				<form onsubmit={handleConfirm} class="mt-6 space-y-4">
					<div>
						<label
							for="reset-code"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.reset_codeLabel()}
						</label>
						<input
							type="text"
							id="reset-code"
							required
							bind:value={code}
							placeholder="123456"
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<div>
						<label
							for="new-password"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.reset_newPasswordLabel()}
						</label>
						<input
							type="password"
							id="new-password"
							required
							minlength="8"
							bind:value={newPassword}
							placeholder={m.login_passwordPlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<div>
						<label
							for="confirm-new-password"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.reset_confirmPasswordLabel()}
						</label>
						<input
							type="password"
							id="confirm-new-password"
							required
							minlength="8"
							bind:value={confirmPassword}
							placeholder={m.login_passwordPlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<button
						type="submit"
						disabled={submitting}
						class="w-full rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none disabled:opacity-50 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
					>
						{submitting ? m.reset_confirmSubmitting() : m.reset_confirmSubmit()}
					</button>
				</form>
			{/if}
		</div>
	</div>
</div>
