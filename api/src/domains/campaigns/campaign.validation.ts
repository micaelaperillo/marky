import dayjs from "dayjs";
import customParseFormat from "dayjs/plugin/customParseFormat.js";
import z from "zod";

dayjs.extend(customParseFormat);

const CAMPAIGN_RULES = {
	CAMPAIGN_MAX_LENGTH: 16,
	CAMPAIGN_MIN_LENGTH: 1,
	CAMPAIGN_NAME_PATTERN: /^[a-z_]+$/i,
} as const;

const TOPIC_RULES = {
	TOPIC_MAX_LENGTH: 15,
	TOPIC_MIN_LENGTH: 1,
	TOPIC_PATTERN: /^[a-z _]+$/i,
	TOPICS_ARRAY_MAX_SIZE: 6,
	TOPICS_ARRAY_MIN_SIZE: 1,
} as const;

const DATE_RANGE_RULES = {
	DATE_RANGE_MAX_LENGTH: 30,
} as const;

const TopicSchema = z
	.string()
	.regex(TOPIC_RULES.TOPIC_PATTERN)
	.min(TOPIC_RULES.TOPIC_MIN_LENGTH)
	.max(TOPIC_RULES.TOPIC_MAX_LENGTH);

export const CampaignInputSchema = z
	.object({
		campaign: z
			.string()
			.regex(CAMPAIGN_RULES.CAMPAIGN_NAME_PATTERN)
			.min(CAMPAIGN_RULES.CAMPAIGN_MIN_LENGTH)
			.max(CAMPAIGN_RULES.CAMPAIGN_MAX_LENGTH),
		end: z.string().refine((s) => dayjs(s, "YYYY-MM-DD", true).isValid()),
		start: z.string().refine((s) => dayjs(s, "YYYY-MM-DD", true).isValid()),
		topics: z
			.array(TopicSchema)
			.min(TOPIC_RULES.TOPICS_ARRAY_MIN_SIZE)
			.max(TOPIC_RULES.TOPICS_ARRAY_MAX_SIZE)
			.refine(
				(topics) =>
					new Set(topics.map((t) => t.toLowerCase())).size === topics.length,
				{ message: "Topics must be unique" },
			),
	})
	// Date range is [start, end) - end date is exclusive
	.refine(
		({ start, end }) => {
			const s = dayjs(start);
			const e = dayjs(end);
			return (
				s.isBefore(e) &&
				e.diff(s, "day") <= DATE_RANGE_RULES.DATE_RANGE_MAX_LENGTH
			);
		},
		{ message: "End must be after start and range must not exceed 30 days" },
	);

export const CampaignParamsSchema = z.object({
	name: z
		.string()
		.regex(CAMPAIGN_RULES.CAMPAIGN_NAME_PATTERN)
		.min(CAMPAIGN_RULES.CAMPAIGN_MIN_LENGTH)
		.max(CAMPAIGN_RULES.CAMPAIGN_MAX_LENGTH),
});

export const CampaignSchema = z.object({
	end: z.string(),
	name: z.string(),
	start: z.string(),
	topics: z.array(z.string()),
});
