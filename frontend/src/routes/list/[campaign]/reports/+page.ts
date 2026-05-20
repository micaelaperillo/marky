import { error } from '@sveltejs/kit';
import { apiFetch } from '$lib/api';
import type { PageLoad } from './$types';

type SentimentPoint = {
	timestamp: string;
	sentiment: number;
};

type ReportItem = {
	campaignId: string;
	timestamp: string;
	sentiment: number;
	report?: Record<string, unknown>;
};

export const load: PageLoad = async ({ fetch, params, url }) => {
	const campaignRes = await apiFetch(`/campaigns/${params.campaign}`, {}, fetch);
	if (campaignRes.status === 404) {
		throw error(404, 'Campaign not found');
	}
	if (!campaignRes.ok) {
		throw error(campaignRes.status, 'Failed to load campaign');
	}
	const campaign = await campaignRes.json();

	const start = url.searchParams.get('start');
	const end = url.searchParams.get('end');

	if (start && end) {
		const res = await apiFetch(
			`/reports/range?campaignId=${campaign.id}&start=${encodeURIComponent(start)}&end=${encodeURIComponent(end)}`,
			{},
			fetch
		);
		const reports: ReportItem[] = res.ok ? await res.json() : [];
		const sorted = [...reports].sort((a, b) => b.timestamp.localeCompare(a.timestamp));
		return { campaign, mode: 'range' as const, reports: sorted, range: { start, end } };
	}

	const sStart = campaign.start ?? campaign.start_date;
	const sEnd = new Date().toISOString();
	const res = await apiFetch(
		`/reports/sentiment?campaignId=${campaign.id}&start=${encodeURIComponent(sStart)}&end=${encodeURIComponent(sEnd)}`,
		{},
		fetch
	);
	const points: SentimentPoint[] = res.ok ? await res.json() : [];
	const last5 = [...points].sort((a, b) => b.timestamp.localeCompare(a.timestamp)).slice(0, 5);
	return { campaign, mode: 'default' as const, points: last5 };
};
