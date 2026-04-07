import type { PageServerLoad, Actions } from './$types';

import { putCampaign, putTask } from '$lib/server/dynamo';

import dayjs from 'dayjs';

import { error, redirect } from '@sveltejs/kit';

export const load = (async ({ cookies }) => {
	const user = cookies.get('user_id');

	if (!user) {
		redirect(303, '/login');
	}

	return { user };
}) satisfies PageServerLoad;

export const actions = {
	default: async ({ request, cookies }) => {
		//#region Params

		const user = cookies.get('user_id');
		if (!user) {
			redirect(303, '/login');
		}

		const form = await request.formData();

		const campaign = form.get('campaign') as string;
		const topics = form.getAll('topic') as string[];
		const start = dayjs(form.get('start') as string).startOf('day');
		const end = dayjs(form.get('end') as string).startOf('day');

		const today = dayjs().startOf('day');
		const tomorrow = today.add(1, 'day');

		//#endregion

		//#region Validations

		if (campaign.length > 16) {
			error(400, 'campaign name may only have 16 letters');
		}

		if (!/[a-z_]+/i.test(campaign)) {
			error(400, 'campaign name may only have ASCII letters and _');
		}

		if (topics.some((t) => t.length > 10)) {
			error(400, 'some topics exceed 10 chars');
		}

		if (end.isBefore(start)) {
			error(400, "end can't come before the start");
		}

		if (start.diff(end, 'days') > 30) {
			error(400, "the interval can't be greater than 30 days");
		}

		//#endregion

		//#region DB population

		const promises: Promise<unknown>[] = [];

		let iterator = dayjs(start);
		while (iterator.isBefore(end)) {
			const when = iterator.isBefore(today) ? tomorrow : iterator.add(1, 'day');

			for (const topic of topics) {
				promises.push(putTask(when, topic, iterator));
			}

			iterator = iterator.add(1, 'day');
		}

		await Promise.allSettled(promises);
		await putCampaign(user, campaign, topics, start, end);

		//#endregion

		redirect(303, `/list/${campaign}`);
	}
} satisfies Actions;
