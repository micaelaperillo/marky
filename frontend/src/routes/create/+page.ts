import { redirect } from '@sveltejs/kit';
import { base } from '$app/paths';
import { getAccessToken } from '$lib/auth';
import type { PageLoad } from './$types';

export const load: PageLoad = async () => {
	const token = await getAccessToken();
	if (!token) throw redirect(303, `${base}/login`);
};
