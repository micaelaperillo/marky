/**
 * Form configuration shared between client and server.
 * Update values here — both the UI and the server action will follow.
 */
export const formConfig = {
	campaign: {
		maxLength: 32,
		minLength: 1,
		/** Regex used on the server for validation. */
		pattern: /^[A-Za-z0-9_-]+$/,
		/** HTML-safe version of the pattern (no anchors) for the `pattern` attribute. */
		patternHtml: '[A-Za-z0-9_\\-]+',
		placeholder: 'product-launch'
	},
	range: {
		/** Maximum interval between start and end date, in days. */
		maxDays: 30
	},
	topics: {
		/** Maximum number of topics allowed per campaign. */
		max: 10,
		/** Minimum number of topics the user must provide. */
		min: 1,
		topic: {
			maxLength: 40,
			minLength: 1
		},
		pattern: /^[\p{L}\p{N} _-]+$/u
	}
} as const;

export type FormConfig = typeof formConfig;
