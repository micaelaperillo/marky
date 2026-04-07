import { error } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions = {
	default: async ({ request, cookies }) => {
		const form = await request.formData();
		const user = form.get('id');

		if (typeof user !== 'string') {
			error(400);
		}

		cookies.set('user_id', user, { path: '/' });
	}
} satisfies Actions;
