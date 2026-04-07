import type { PageServerLoad } from './$types';

import { getCampaign } from '$lib/server/dynamo';

export const load = (async ({ parent, params }) => {
	const { user } = await parent();
	const { campaign } = params;
	return await getCampaign(user, campaign);
}) satisfies PageServerLoad;
