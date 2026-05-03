import { error, redirect } from "@sveltejs/kit";
import { base } from "$app/paths";
import type { PageLoad } from "./$types";

export const load: PageLoad = async ({ fetch, params }) => {
	const res = await fetch(`${base}/api/campaigns/${params.campaign}`);
	if (res.status === 401) {
		throw redirect(303, `${base}/login`);
	}
	if (res.status === 404) {
		throw error(404, "Campaign not found");
	}
	const campaign = await res.json();
	return { campaign };
};
