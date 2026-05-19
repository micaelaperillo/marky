import { base } from '$app/paths';
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

export async function apiFetch(
	path: string,
	opts: RequestInit = {},
	fetchFn: typeof fetch = fetch
): Promise<Response> {
	const token = await getAccessToken();
	const headers = new Headers(opts.headers);
	if (token) headers.set('Authorization', `Bearer ${token}`);

	const res = await fetchFn(`${base}${path}`, { ...opts, headers });

	if (res.status === 401 && token) {
		const refreshed = await refreshOnce();
		if (refreshed) {
			headers.set('Authorization', `Bearer ${refreshed}`);
			return fetchFn(`${base}${path}`, { ...opts, headers });
		}
		window.location.href = `${base}/login`;
	}
	return res;
}
