import { resolve } from '$app/paths';
import { getAccessToken } from './auth';

let refreshPromise: Promise<string | null> | null = null;

function refreshOnce(): Promise<string | null> {
	if (!refreshPromise) {
		refreshPromise = getAccessToken().finally(() => {
			refreshPromise = null;
		});
	}
	return refreshPromise;
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '';

export async function apiFetch(
	path: string,
	opts: RequestInit = {},
	fetchFn: typeof fetch = fetch
): Promise<Response> {
	const token = await getAccessToken();
	const headers = new Headers(opts.headers);
	if (token) headers.set('Authorization', `Bearer ${token}`);

	const url = `${API_BASE_URL}${path}`;

	const res = await fetchFn(url, { ...opts, headers });

	if (res.status === 401 && token) {
		const refreshed = await refreshOnce();
		if (refreshed) {
			headers.set('Authorization', `Bearer ${refreshed}`);
			return fetchFn(url, { ...opts, headers });
		}
		window.location.href = resolve('/login');
	}

	return res;
}
