import { getCampaign } from '$lib/server/dynamo';
import type { Actions, PageServerLoad } from './$types';

export const load = (async ({ parent, params }) => {
	const { user } = await parent();
	const { campaign } = params;
	return await getCampaign(user, campaign);
}) satisfies PageServerLoad;

export const actions = {
	analyze: async ({ params, fetch, cookies }) => {
		const user = cookies.get('user_id') || 'anonymous'; 
		const { campaign: name } = params;

		const result = await getCampaign(user, name);
		const item = result.Item;

		if (!item) {
			return { error: 'Campaign not found' };
		}

		const topics = (item.Topics || []).join(',');
		const start = item.Start;
		const end = item.End;

		try {
			const resp = await fetch(`http://127.0.0.1:8000/api/analyze?start=${start}&end=${end}&topics=${encodeURIComponent(topics)}`);
			if (!resp.ok) {
				const err = await resp.text();
				return { error: `Backend error: ${err}` };
			}
			const data = await resp.json();
			return { report: data.report };
		} catch (e) {
			return { error: `Failed to connect to backend: ${e}` };
		}
	}
} satisfies Actions;
