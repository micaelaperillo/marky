import { redirect } from "@sveltejs/kit";
import { base } from "$app/paths";
import type { LayoutLoad } from "./$types";

export const load: LayoutLoad = async ({ fetch }) => {
	const res = await fetch(`${base}/api/auth/me`);
	if (res.status === 401) {
		throw redirect(303, `${base}/login`);
	}
	const { userId } = await res.json();
	return { user: userId };
};
