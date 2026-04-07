import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

export const load = (async ({ cookies }) => {
	const user = cookies.get('user_id');

	if (!user) {
		redirect(303, '/login');
	}

	return { user };
}) satisfies LayoutServerLoad;
