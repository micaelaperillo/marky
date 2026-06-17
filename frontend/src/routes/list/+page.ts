import { error } from '@sveltejs/kit';
import { apiFetch } from '$lib/api';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch, url }) => {
	const status = url.searchParams.get('status') || 'all';
	const res = await apiFetch(`/campaigns?status=${status}`, {}, fetch);
	if (!res.ok) {
		throw error(res.status, 'Failed to load campaigns');
	}
	const { campaigns, stats } = await res.json();
	return { campaigns, stats, status };
};
