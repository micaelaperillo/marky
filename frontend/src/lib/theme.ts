import { writable } from "svelte/store";

export type Theme = "light" | "dark";

const STORAGE_KEY = "marky.theme";

function detect(): Theme {
	if (typeof window === "undefined") return "light";
	try {
		const stored = localStorage.getItem(STORAGE_KEY);
		if (stored === "light" || stored === "dark") return stored;
	} catch {
		/* storage may throw in private mode */
	}
	return window.matchMedia?.("(prefers-color-scheme: dark)").matches
		? "dark"
		: "light";
}

function apply(theme: Theme) {
	if (typeof document === "undefined") return;
	const root = document.documentElement;
	root.classList.toggle("dark", theme === "dark");
	root.style.colorScheme = theme;
}

export const theme = writable<Theme>("light");

if (typeof window !== "undefined") {
	const initial = detect();
	theme.set(initial);
	apply(initial);
	theme.subscribe((t) => {
		try {
			localStorage.setItem(STORAGE_KEY, t);
		} catch {
			/* noop */
		}
		apply(t);
	});
}

export function toggleTheme() {
	theme.update((t) => (t === "dark" ? "light" : "dark"));
}
