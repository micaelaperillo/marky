import { redirect } from "@sveltejs/kit";
import { base } from "$app/paths";
import type { PageLoad } from "./$types";

export const load: PageLoad = async ({ fetch }) => {
	const res = await fetch(`${base}/api/campaigns`);
	if (res.status === 401) {
		throw redirect(303, `${base}/login`);
	}
	const campaigns = await res.json();
	return { campaigns };
};
