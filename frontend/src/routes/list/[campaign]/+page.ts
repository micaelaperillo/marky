import { error } from '@sveltejs/kit';
import { apiFetch } from '$lib/api';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch, params }) => {
	const res = await apiFetch(`/campaigns/${params.campaign}`, {}, fetch);
	if (res.status === 404) {
		throw error(404, 'Campaign not found');
	}
	if (!res.ok) {
		throw error(res.status, 'Failed to load campaign');
	}
	const campaign = await res.json();
	return { campaign };
};
