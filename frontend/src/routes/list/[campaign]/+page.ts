import { error } from '@sveltejs/kit';
import { base } from '$app/paths';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch, params }) => {
	const res = await fetch(`${base}/api/campaigns/${params.campaign}`);
	if (res.status === 404) {
		throw error(404, 'Campaign not found');
	}
	if (!res.ok) {
		throw error(res.status, 'Failed to load campaign');
	}
	const campaign = await res.json();
	return { campaign };
};
