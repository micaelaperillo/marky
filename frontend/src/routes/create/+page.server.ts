import { error, redirect } from '@sveltejs/kit';
import dayjs from 'dayjs';
import { formConfig } from '$lib/config';
import { putCampaign, putTask } from '$lib/server/dynamo';
import type { Actions, PageServerLoad } from './$types';

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

		const campaignRaw = form.get('campaign');
		const startRaw = form.get('start');
		const endRaw = form.get('end');
		const topicsRaw = form.getAll('topic');

		if (typeof campaignRaw !== 'string') {
			error(400, 'missing campaign name');
		}
		if (typeof startRaw !== 'string' || typeof endRaw !== 'string') {
			error(400, 'missing date range');
		}

		const campaign = campaignRaw;
		const topics = topicsRaw.filter((t): t is string => typeof t === 'string');
		const start = dayjs(startRaw).startOf('day');
		const end = dayjs(endRaw).startOf('day');

		if (!start.isValid() || !end.isValid()) {
			error(400, 'invalid date');
		}

		const today = dayjs().startOf('day');
		const tomorrow = today.add(1, 'day');

		//#endregion

		//#region Validations

		const { campaign: campaignCfg, topics: topicsCfg, range: rangeCfg } = formConfig;

		if (campaign.length < campaignCfg.minLength || campaign.length > campaignCfg.maxLength) {
			error(
				400,
				`campaign name must be ${campaignCfg.minLength}-${campaignCfg.maxLength} characters`
			);
		}

		if (!campaignCfg.pattern.test(campaign)) {
			error(400, 'campaign name may only have ASCII letters and _');
		}

		if (topics.length < topicsCfg.min || topics.length > topicsCfg.max) {
			error(400, `topics count must be between ${topicsCfg.min} and ${topicsCfg.max}`);
		}

		if (new Set(topics).size !== topics.length) {
			error(400, 'duplicate topics are not allowed');
		}

		if (
			topics.some(
				(t) => t.length < topicsCfg.topic.minLength || t.length > topicsCfg.topic.maxLength
			)
		) {
			error(
				400,
				`each topic must be ${topicsCfg.topic.minLength}-${topicsCfg.topic.maxLength} characters`
			);
		}

		if (topics.some((t) => !topicsCfg.pattern.test(t))) {
			error(400, 'topics may only have ASCII letters, spaces and _');
		}

		if (end.isBefore(start)) {
			error(400, "end can't come before the start");
		}

		if (end.diff(start, 'day') > rangeCfg.maxDays) {
			error(400, `the interval can't be greater than ${rangeCfg.maxDays} days`);
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

		const results = await Promise.allSettled(promises);
		const failed = results.filter((r) => r.status === 'rejected');
		if (failed.length > 0) {
			console.error('putTask rejections', failed);
			error(500, 'failed to schedule tasks');
		}
		await putCampaign(user, campaign, topics, start, end);

		//#endregion

		redirect(303, `/list/${campaign}`);
	}
} satisfies Actions;
