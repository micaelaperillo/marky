/**
 * Form configuration shared between client and server.
 * Update values here — both the UI and the server action will follow.
 */
export const formConfig = {
	campaign: {
		maxLength: 16,
		minLength: 1,
		/** Regex used on the server for validation. */
		pattern: /^[A-Za-z_]+$/,
		/** HTML-safe version of the pattern (no anchors) for the `pattern` attribute. */
		patternHtml: '[A-Za-z_]+',
		placeholder: 'q2_launch'
	},
	range: {
		/** Maximum interval between start and end date, in days. */
		maxDays: 30
	},
	topics: {
		/** Maximum number of topics allowed per campaign. */
		max: 6,
		/** Minimum number of topics the user must provide. */
		min: 1,
		topic: {
			maxLength: 15,
			minLength: 1
		}
	}
} as const;

export type FormConfig = typeof formConfig;
