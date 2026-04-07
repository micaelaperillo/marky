import type { PageServerLoad } from './$types';

import { getAllCampaigns } from '$lib/server/dynamo';

export const load = (async ({ parent }) => {
	const { user } = await parent();
	return await getAllCampaigns(user);
}) satisfies PageServerLoad;
