import { getAllCampaigns } from '$lib/server/dynamo';
import type { PageServerLoad } from './$types';

export const load = (async ({ parent }) => {
	const { user } = await parent();

	try {
		const res = await getAllCampaigns(user);
		return { Items: res.Items ?? [] };
	} catch (err) {
		console.error('getAllCampaigns failed', err);
		return { Items: [] };
	}
}) satisfies PageServerLoad;
