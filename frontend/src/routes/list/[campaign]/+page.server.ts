import { env } from "$env/dynamic/private";
import { getCampaign } from "$lib/server/dynamo";
import type { Actions, PageServerLoad } from "./$types";

const BACKEND_URL = env.MARKY_BACKEND_URL ?? "http://127.0.0.1:8000";

export const load = (async ({ parent, params }) => {
	const { user } = await parent();
	const { campaign } = params;

	try {
		const result = await getCampaign(user, campaign);
		return { Item: result.Item ?? null };
	} catch (err) {
		console.error("getCampaign failed", err);
		return { Item: null };
	}
}) satisfies PageServerLoad;

export const actions = {
	analyze: async ({ params, parent }) => {
		const { user } = await parent();
		const { campaign: name } = params;

		let item;
		try {
			const result = await getCampaign(user, name);
			item = result.Item;
		} catch {
			return { error: "Failed to load campaign data." };
		}

		if (!item) {
			return { error: "Campaign not found" };
		}

		const topics = (item.Topics || []).join(",");
		const start = item.Start;
		const end = item.End;

		if (!start || !end) {
			return { error: "Campaign is missing date range." };
		}

		if (!topics) {
			return { error: "Campaign has no topics to analyze." };
		}

		try {
			const url = new URL("/api/analyze", BACKEND_URL);
			url.searchParams.set("start", start);
			url.searchParams.set("end", end);
			url.searchParams.set("topics", topics);

			const controller = new AbortController();
			const timeout = setTimeout(() => controller.abort(), 30_000);
			const resp = await fetch(url, { signal: controller.signal });
			clearTimeout(timeout);

			if (!resp.ok) {
				return {
					error: "Analysis service returned an error. Please try again.",
				};
			}

			let data;
			try {
				data = await resp.json();
			} catch {
				return { error: "Analysis service returned an invalid response." };
			}
			return { report: data.report };
		} catch (err) {
			if (err instanceof Error && err.name === "AbortError") {
				return { error: "Analysis timed out. Please try again later." };
			}
			return { error: "Unable to connect to analysis service." };
		}
	},
} satisfies Actions;
