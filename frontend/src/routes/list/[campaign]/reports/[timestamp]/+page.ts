import { error } from '@sveltejs/kit';
import { apiFetch } from '$lib/api';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch, params }) => {
	const campaignRes = await apiFetch(`/campaigns/${params.campaign}`, {}, fetch);
	if (campaignRes.status === 404) {
		throw error(404, 'Campaign not found');
	}
	if (!campaignRes.ok) {
		throw error(campaignRes.status, 'Failed to load campaign');
	}
	const campaign = await campaignRes.json();

	const timestamp = decodeURIComponent(params.timestamp);
	const reportRes = await apiFetch(
		`/reports/?campaignId=${campaign.id}&timestamp=${encodeURIComponent(timestamp)}`,
		{},
		fetch
	);
	if (reportRes.status === 404) {
		throw error(404, 'Report not found');
	}
	if (!reportRes.ok) {
		throw error(reportRes.status, 'Failed to load report');
	}
	const report = await reportRes.json();

	return { campaign, report, timestamp };
};
