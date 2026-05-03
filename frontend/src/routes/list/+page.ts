import { error } from '@sveltejs/kit';
import { base } from '$app/paths';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch }) => {
	const res = await fetch(`${base}/api/campaigns`);
	if (!res.ok) {
		throw error(res.status, 'Failed to load campaigns');
	}
	const campaigns = await res.json();
	return { campaigns };
};
