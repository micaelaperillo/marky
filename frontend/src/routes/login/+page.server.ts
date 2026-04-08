import type { Actions } from './$types';

import { error, redirect } from '@sveltejs/kit';

export const actions = {
	default: async ({ request, cookies }) => {
		const form = await request.formData();
		const user = form.get('id');

		if (typeof user !== 'string') {
			error(400);
		}

		cookies.set('user_id', user, { path: '/' });

		redirect(303, '/');
	}
} satisfies Actions;
