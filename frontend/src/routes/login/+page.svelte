<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { signIn, signUp, confirmSignUp } from '$lib/auth';
	import { m } from '$lib/paraglide/messages';

	let mode = $state<'signin' | 'signup' | 'confirm'>('signin');
	let email = $state('');
	let password = $state('');
	let confirmPassword = $state('');
	let code = $state('');
	let submitting = $state(false);
	let errorMsg = $state('');
	let successMsg = $state('');

	function mapError(err: unknown): string {
		if (!(err instanceof Error)) return m.login_errorUnknown();
		const errCode = (err as { code?: string }).code;
		switch (errCode) {
			case 'UsernameExistsException':
				return m.login_errorUserExists();
			case 'NotAuthorizedException':
				return m.login_errorWrongPassword();
			case 'InvalidPasswordException':
				return m.login_errorWeakPassword();
			case 'CodeMismatchException':
				return m.login_errorInvalidCode();
			case 'ExpiredCodeException':
				return m.login_errorExpiredCode();
			case 'UserNotConfirmedException':
				return m.login_errorNotConfirmed();
			default:
				return err.message || m.login_errorUnknown();
		}
	}

	async function handleSignIn(e: SubmitEvent) {
		e.preventDefault();
		if (!email || !password) return;
		errorMsg = '';
		submitting = true;
		try {
			await signIn(email, password);
			goto(resolve('/list'));
		} catch (err) {
			errorMsg = mapError(err);
		} finally {
			submitting = false;
		}
	}

	async function handleSignUp(e: SubmitEvent) {
		e.preventDefault();
		if (!email || !password) return;
		if (password !== confirmPassword) {
			errorMsg = m.login_errorPasswordMismatch();
			return;
		}
		errorMsg = '';
		submitting = true;
		try {
			await signUp(email, password);
			mode = 'confirm';
		} catch (err) {
			errorMsg = mapError(err);
		} finally {
			submitting = false;
		}
	}

	async function handleConfirm(e: SubmitEvent) {
		e.preventDefault();
		if (!email || !code) return;
		errorMsg = '';
		submitting = true;
		try {
			await confirmSignUp(email, code);
			successMsg = m.login_signupSuccess();
			mode = 'signin';
			code = '';
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
				{mode === 'signup'
					? m.login_signupTitle()
					: mode === 'confirm'
						? m.login_confirmTitle()
						: m.login_title()}
			</h1>
			<p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
				{mode === 'confirm' ? m.login_confirmSubtitle() : m.login_subtitle()}
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

			{#if successMsg}
				<div
					role="status"
					class="mt-4 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700 dark:border-emerald-900 dark:bg-emerald-950/50 dark:text-emerald-300"
				>
					{successMsg}
				</div>
			{/if}

			{#if mode === 'signin'}
				<form onsubmit={handleSignIn} class="mt-6 space-y-4">
					<div>
						<label
							for="email"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.login_emailLabel()}
						</label>
						<input
							type="email"
							id="email"
							required
							bind:value={email}
							placeholder={m.login_emailPlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<div>
						<label
							for="password"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.login_passwordLabel()}
						</label>
						<input
							type="password"
							id="password"
							required
							bind:value={password}
							placeholder={m.login_passwordPlaceholder()}
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
					<div class="flex items-center justify-between text-sm">
						<button
							type="button"
							onclick={() => {
								mode = 'signup';
								errorMsg = '';
								successMsg = '';
							}}
							class="text-brand-600 hover:underline dark:text-brand-400"
						>
							{m.login_switchToSignup()}
						</button>
						<a
							href={resolve('/reset-password')}
							class="text-slate-500 hover:underline dark:text-slate-400"
						>
							{m.login_forgotPassword()}
						</a>
					</div>
				</form>
			{:else if mode === 'signup'}
				<form onsubmit={handleSignUp} class="mt-6 space-y-4">
					<div>
						<label
							for="signup-email"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.login_emailLabel()}
						</label>
						<input
							type="email"
							id="signup-email"
							required
							bind:value={email}
							placeholder={m.login_emailPlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<div>
						<label
							for="signup-password"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.login_passwordLabel()}
						</label>
						<input
							type="password"
							id="signup-password"
							required
							minlength="8"
							bind:value={password}
							placeholder={m.login_passwordPlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<div>
						<label
							for="signup-confirm"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.login_confirmPasswordLabel()}
						</label>
						<input
							type="password"
							id="signup-confirm"
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
						{submitting ? m.login_signupSubmitting() : m.login_signupSubmit()}
					</button>
					<button
						type="button"
						onclick={() => {
							mode = 'signin';
							errorMsg = '';
						}}
						class="w-full text-center text-sm text-brand-600 hover:underline dark:text-brand-400"
					>
						{m.login_switchToSignin()}
					</button>
				</form>
			{:else}
				<form onsubmit={handleConfirm} class="mt-6 space-y-4">
					<div>
						<label
							for="confirm-code"
							class="block text-sm font-semibold text-slate-900 dark:text-slate-100"
						>
							{m.login_confirmCodeLabel()}
						</label>
						<input
							type="text"
							id="confirm-code"
							required
							bind:value={code}
							placeholder={m.login_confirmCodePlaceholder()}
							class="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 shadow-xs transition placeholder:text-slate-400 focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:placeholder:text-slate-500"
						/>
					</div>
					<button
						type="submit"
						disabled={submitting}
						class="w-full rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-slate-900/10 transition hover:bg-slate-800 focus-visible:ring-2 focus-visible:ring-brand-500/40 focus-visible:outline-none disabled:opacity-50 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
					>
						{submitting ? m.login_confirmSubmitting() : m.login_confirmSubmit()}
					</button>
				</form>
			{/if}
		</div>

		<p class="mt-6 text-center text-xs text-slate-500 dark:text-slate-400">{m.login_footer()}</p>
	</div>
</div>
