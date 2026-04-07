import { derived, get, writable } from "svelte/store";

export type Locale = "en" | "es";

const messages = {
	en: {
		campaign: {
			breadcrumb: "Campaigns",
			eyebrow: "Campaign",
			noTopics: "No topics in this campaign.",
			notFoundBody:
				"We couldn't locate this campaign. It may have been deleted or the name is incorrect.",
			notFoundCta: "Back to campaigns",
			notFoundTitle: "Campaign not found",
			reportsHeading: "Reports",
			reportsPlaceholder:
				"Sentiment reports will appear here once ingestion runs.",
			statusActive: "Active",
			statusEnded: "Ended",
			topicSubtitle: "Sentiment tracked daily",
			topicsHeading: "Tracked topics",
		},
		common: {
			back: "Go back",
			cancel: "Cancel",
			dashboard: "Open dashboard",
			home: "Back to home",
			signedIn: "Signed in",
			signIn: "Sign in",
			view: "View",
		},
		create: {
			breadcrumbCampaigns: "Campaigns",
			breadcrumbNew: "New",
			endLabel: "End date",
			errorDuplicate: '"{topic}" already added',
			errorMax: "Maximum {max} topics",
			errorMinLen: "Topic must be at least {minLen} character{plural}",
			intervalHint: "Maximum interval: {max} days.",
			nameHint: "Up to {max} characters. Letters and underscores only.",
			nameLabel: "Campaign name",
			removeTopic: "Remove {topic}",
			startLabel: "Start date",
			submit: "Create campaign",
			subtitle:
				"Pick a name, list the topics you want to track, and set the date range.",
			title: "Create a campaign",
			topicCounter: "{count} / {max}",
			topicPlaceholder: "Type a topic and press Enter…",
			topicsHint:
				"Press Enter or comma to add a topic. Up to {max}, {minLen}-{maxLen} characters each.",
			topicsLabel: "Topics",
		},
		errors: {
			"404": {
				body: "We couldn't find the page you were looking for. It may have been moved or never existed.",
				code: "404",
				title: "Page not found",
			},
			"500": {
				body: "Our servers tripped over a wire. The team has been notified — try again in a moment.",
				code: "500",
				title: "Something went wrong",
			},
			detail: "Detail",
			generic: {
				body: "An unexpected error occurred. Please try again.",
				code: "Error",
				title: "Unexpected error",
			},
		},
		home: {
			badge: "Sentiment-driven marketing intelligence",
			createCampaign: "Create campaign",
			openDashboard: "Open dashboard",
			subtitle:
				"Spin up campaigns, ingest signals from prediction markets, and watch sentiment unfold — all in one calm dashboard.",
			titleLine1: "Track the pulse of",
			titleLine2: "your markets.",
		},
		list: {
			badgeDaysLeft: "{days}d left",
			badgeEnded: "Ended",
			badgeEndsToday: "Ends today",
			emptyBody:
				"Campaigns let you track topics over time and measure sentiment across prediction markets.",
			emptyCta: "Create your first campaign",
			emptyLead: "No campaigns yet — kick one off to start tracking sentiment.",
			emptyTitle: "No campaigns yet",
			eyebrow: "Dashboard",
			newCampaign: "New campaign",
			statCampaigns: "Campaigns",
			statRunning: "Running now",
			statTopics: "Topics tracked",
			summary:
				"{count} active {count, plural, one {campaign} other {campaigns}} being monitored.",
			title: "Your campaigns",
			topicCount: "{count} {count, plural, one {topic} other {topics}}",
		},
		login: {
			footer: "By signing in you agree to track sentiment responsibly.",
			submit: "Sign in",
			subtitle: "Sign in with your user ID to continue.",
			title: "Welcome back",
			userIdLabel: "User ID",
			userIdPlaceholder: "your_user_id",
		},
		nav: {
			campaigns: "Campaigns",
			newCampaign: "New campaign",
		},
		theme: {
			toDark: "Switch to dark mode",
			toLight: "Switch to light mode",
		},
	},
	es: {
		campaign: {
			breadcrumb: "Campañas",
			eyebrow: "Campaña",
			noTopics: "Esta campaña no tiene temas cargados.",
			notFoundBody:
				"No la pudimos ubicar. Capaz la borraste o el nombre está mal escrito.",
			notFoundCta: "Volver a campañas",
			notFoundTitle: "No encontramos esta campaña",
			reportsHeading: "Reportes",
			reportsPlaceholder:
				"Acá van a aparecer los reportes cuando corra la ingesta.",
			statusActive: "Activa",
			statusEnded: "Terminó",
			topicSubtitle: "Sentimiento medido todos los días",
			topicsHeading: "Temas en seguimiento",
		},
		common: {
			back: "Volver",
			cancel: "Cancelar",
			dashboard: "Abrir el panel",
			home: "Volver al inicio",
			signedIn: "Sesión activa",
			signIn: "Ingresar",
			view: "Ver",
		},
		create: {
			breadcrumbCampaigns: "Campañas",
			breadcrumbNew: "Nueva",
			endLabel: "Hasta",
			errorDuplicate: '"{topic}" ya lo cargaste, che',
			errorMax: "Pará, el máximo son {max} temas",
			errorMinLen: "El tema tiene que tener al menos {minLen} carácter{plural}",
			intervalHint: "El intervalo no puede pasar de {max} días.",
			nameHint: "Hasta {max} caracteres. Solo letras y guión bajo, nada raro.",
			nameLabel: "Nombre de la campaña",
			removeTopic: "Sacar {topic}",
			startLabel: "Desde",
			submit: "Crear campaña",
			subtitle:
				"Ponele un nombre, cargá los temas que querés seguir y elegí el rango de fechas.",
			title: "Armar una campaña",
			topicCounter: "{count} / {max}",
			topicPlaceholder: "Escribí un tema y dale Enter…",
			topicsHint:
				"Apretá Enter o coma para sumar un tema. Hasta {max}, de {minLen} a {maxLen} caracteres cada uno.",
			topicsLabel: "Temas",
		},
		errors: {
			"404": {
				body: "No pudimos encontrar la página que buscás. Capaz la movieron o nunca existió.",
				code: "404",
				title: "Página no encontrada",
			},
			"500": {
				body: "Algo se cortó del lado nuestro. Ya estamos viendo qué pasó — probá en un rato.",
				code: "500",
				title: "Uh, algo se rompió",
			},
			detail: "Detalle",
			generic: {
				body: "Pasó algo raro. Probá de nuevo en un toque.",
				code: "Error",
				title: "Error inesperado",
			},
		},
		home: {
			badge: "Marketing con pulso de mercado",
			createCampaign: "Armar campaña",
			openDashboard: "Abrir el panel",
			subtitle:
				"Armá campañas, metele señales de los mercados de predicción y mirá cómo se mueve el sentimiento — todo desde un mismo panel, tranqui.",
			titleLine1: "Tomale el pulso",
			titleLine2: "a tus mercados.",
		},
		list: {
			badgeDaysLeft: "quedan {days}d",
			badgeEnded: "Terminó",
			badgeEndsToday: "Termina hoy",
			emptyBody:
				"Con las campañas podés seguir temas en el tiempo y ver cómo se mueve el sentimiento en los mercados de predicción.",
			emptyCta: "Armá tu primera campaña",
			emptyLead:
				"Todavía no armaste ninguna — dale, arrancá una para ver cómo viene el sentimiento.",
			emptyTitle: "Acá no hay nada todavía",
			eyebrow: "Panel",
			newCampaign: "Nueva campaña",
			statCampaigns: "Campañas",
			statRunning: "Corriendo ahora",
			statTopics: "Temas en seguimiento",
			summary:
				"{count} {count, plural, one {campaña activa} other {campañas activas}} en la mira.",
			title: "Tus campañas",
			topicCount: "{count} {count, plural, one {tema} other {temas}}",
		},
		login: {
			footer: "Al ingresar te comprometés a usar esta data con cabeza.",
			submit: "Ingresar",
			subtitle: "Metete con tu ID de usuario y arrancamos.",
			title: "¡Qué bueno verte de nuevo!",
			userIdLabel: "ID de usuario",
			userIdPlaceholder: "tu_id",
		},
		nav: {
			campaigns: "Campañas",
			newCampaign: "Nueva campaña",
		},
		theme: {
			toDark: "Cambiar a modo oscuro",
			toLight: "Cambiar a modo claro",
		},
	},
} as const;

const SUPPORTED: Locale[] = ["en", "es"];
const STORAGE_KEY = "marky.locale";

function isLocale(v: unknown): v is Locale {
	return typeof v === "string" && (SUPPORTED as string[]).includes(v);
}

function detect(): Locale {
	if (typeof window === "undefined") return "en";
	try {
		const stored = localStorage.getItem(STORAGE_KEY);
		if (isLocale(stored)) return stored;
	} catch {
		/* storage may throw in private mode */
	}
	const nav = navigator.language?.slice(0, 2).toLowerCase();
	return isLocale(nav) ? nav : "en";
}

export const locale = writable<Locale>("en");

if (typeof window !== "undefined") {
	locale.set(detect());
	locale.subscribe((l) => {
		try {
			localStorage.setItem(STORAGE_KEY, l);
			document.documentElement.lang = l;
		} catch {
			/* noop */
		}
	});
}

function lookup(loc: Locale, path: string): string {
	const parts = path.split(".");
	let cur: unknown = messages[loc];
	for (const p of parts) {
		if (cur == null || typeof cur !== "object") return path;
		cur = (cur as Record<string, unknown>)[p];
	}
	return typeof cur === "string" ? cur : path;
}

/** Simple ICU-lite plural: `{var, plural, one {x} other {y}}`. */
function plural(
	template: string,
	vars: Record<string, string | number>,
): string {
	return template.replace(
		/\{(\w+),\s*plural,\s*one\s*\{([^}]*)\}\s*other\s*\{([^}]*)\}\}/g,
		(_, key, one, other) => (Number(vars[key]) === 1 ? one : other),
	);
}

function interpolate(
	template: string,
	vars?: Record<string, string | number>,
): string {
	if (!vars) return template;
	const withPlural = plural(template, vars);
	return withPlural.replace(/\{(\w+)\}/g, (_, k) =>
		vars[k] != null ? String(vars[k]) : `{${k}}`,
	);
}

export const t = derived(
	locale,
	($locale) => (key: string, vars?: Record<string, string | number>) =>
		interpolate(lookup($locale, key), vars),
);

export function translate(
	key: string,
	vars?: Record<string, string | number>,
): string {
	return interpolate(lookup(get(locale), key), vars);
}

export const supportedLocales = SUPPORTED;
