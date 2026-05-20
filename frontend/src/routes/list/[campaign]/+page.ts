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
	
	const reportsRes = await apiFetch(`/reports/latest?campaignId=${campaign.id}`, {}, fetch);
	if (!reportsRes.ok) {
		if (reportsRes.status === 404) {
			campaign.reports = [];
			return { campaign, report: null, sentimentTimeline: [], timestamp: null };
		} else {
			throw error(reportsRes.status, 'Failed to load last campaign report');
		}
	}
	const report = await reportsRes.json();
	const timestamp = report ? report.timestamp : null;
	const pointLimit = 10;
	const sentimentRes = await apiFetch(`/reports/sentiment/latest?campaignId=${campaign.id}&limit=${pointLimit}`, {}, fetch);
	if (!sentimentRes.ok) {
		if (sentimentRes.status === 404) {
			campaign.sentiment = null;
		} else {
			throw error(sentimentRes.status, 'Failed to load campaign sentiment');
		}
	}
	const sentimentTimeline = await sentimentRes.json();
	
	return { campaign, report, sentimentTimeline, timestamp };
};
