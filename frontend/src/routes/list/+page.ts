import { error } from '@sveltejs/kit';
import { apiFetch } from '$lib/api';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch }) => {
	const res = await apiFetch('/campaigns', {}, fetch);
	if (!res.ok) {
		throw error(res.status, 'Failed to load campaigns');
	}
	const campaigns = await res.json();
	return { campaigns };
};
