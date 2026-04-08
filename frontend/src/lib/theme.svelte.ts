import { browser } from '$app/environment';

export type Theme = 'light' | 'dark';

const STORAGE_KEY = 'marky.theme';

function detect(): Theme {
	if (!browser) return 'light';

	try {
		const stored = localStorage.getItem(STORAGE_KEY);
		if (stored === 'light' || stored === 'dark') return stored;
	} catch {
		/* storage may throw in private mode */
	}

	return window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function apply(theme: Theme) {
	if (browser) {
		localStorage.setItem(STORAGE_KEY, theme);

		const root = document.documentElement;
		root.classList.toggle('dark', theme === 'dark');
		root.style.colorScheme = theme;
	}
}

let theme = $state<Theme>(detect());

// The destroy method isn't needed, as this code is needed through
// all the site navigation, and if the user closes the page, it is
// forcibly destroyed
if (browser) {
	$effect.root(() => {
		$effect(() => apply(theme));
	});
}

export function getTheme() {
	return theme;
}

export function toggleTheme() {
	theme = theme === 'dark' ? 'light' : 'dark';
}
