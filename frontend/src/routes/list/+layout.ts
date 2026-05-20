import { redirect } from '@sveltejs/kit';
import { resolve } from '$app/paths';
import { apiFetch } from '$lib/api';
import { getAccessToken, getUserEmail } from '$lib/auth';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ fetch }) => {
	const token = await getAccessToken();
	if (!token) throw redirect(303, resolve('/login'));

	const res = await apiFetch('/auth/me', {}, fetch);
	if (res.status === 401) throw redirect(303, resolve('/login'));
	if (!res.ok) throw new Error('Failed to verify session');

	const { userId } = await res.json();
	const email = await getUserEmail();
	return { email, user: userId };
};
