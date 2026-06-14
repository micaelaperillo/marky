import z from "zod";
import dayjs from "dayjs";
import customParseFormat from "dayjs/plugin/customParseFormat.js";
import utc from "dayjs/plugin/utc.js";

dayjs.extend(customParseFormat);
dayjs.extend(utc);

const CAMPAIGN_RULES = {
    CAMPAIGN_MAX_LENGTH: 100,
    CAMPAIGN_MIN_LENGTH: 1
} as const;

const TOPIC_RULES = {
    TOPIC_MAX_LENGTH: 40,
    TOPIC_MIN_LENGTH: 1,
    TOPIC_PATTERN: /^[\p{L}\p{N} _-]+$/u,
    TOPICS_ARRAY_MAX_SIZE: 10,
    TOPICS_ARRAY_MIN_SIZE: 1
} as const;

const DATE_RANGE_RULES = {
    DATE_RANGE_MAX_LENGTH: 30
} as const;

const TopicSchema = z
    .string()
    .min(TOPIC_RULES.TOPIC_MIN_LENGTH, {
        message: `Topic cannot be empty`
    })
    .max(TOPIC_RULES.TOPIC_MAX_LENGTH, {
        message: `Topic must be at most ${TOPIC_RULES.TOPIC_MAX_LENGTH} characters`
    })
    .regex(TOPIC_RULES.TOPIC_PATTERN, {
        message:
            "Topic can only contain letters, digits, spaces, hyphens and underscores"
    });

export const CampaignInputSchema = z
    .object({
        campaign: z
            .string()
            .trim()
            .min(CAMPAIGN_RULES.CAMPAIGN_MIN_LENGTH, {
                message: "Campaign name cannot be empty"
            })
            .max(CAMPAIGN_RULES.CAMPAIGN_MAX_LENGTH, {
                message: `Campaign name must be at most ${CAMPAIGN_RULES.CAMPAIGN_MAX_LENGTH} characters`
            }),
        start: z
            .string()
            .refine((s) => dayjs(s).isValid(), {
                message: "Start date is invalid"
            })
            .transform((s) => dayjs.utc(s).toISOString()),
        end: z
            .string()
            .refine((s) => dayjs(s).isValid(), {
                message: "End date is invalid"
            })
            .transform((s) => dayjs.utc(s).toISOString()),
        topics: z
            .array(TopicSchema)
            .min(TOPIC_RULES.TOPICS_ARRAY_MIN_SIZE, {
                message: "Add at least one topic"
            })
            .max(TOPIC_RULES.TOPICS_ARRAY_MAX_SIZE, {
                message: `You can add at most ${TOPIC_RULES.TOPICS_ARRAY_MAX_SIZE} topics`
            })
            .refine(
                (topics) =>
                    new Set(topics.map((t) => t.toLowerCase())).size ===
                    topics.length,
                { message: "Topics must be unique" }
            )
    })
    .refine(
        ({ start }) => {
            const now = dayjs.utc();
            const startDate = dayjs.utc(start);
            return !startDate.isBefore(now);
        },
        {
            message: "Start date cannot be in the past",
            path: ["start"]
        }
    )
    .refine(
        ({ start, end }) => dayjs.utc(start).isBefore(dayjs.utc(end)),
        {
            message: "End date must be after start date",
            path: ["end"]
        }
    )
    .refine(
        ({ start, end }) =>
            dayjs.utc(end).diff(dayjs.utc(start), "day") <=
            DATE_RANGE_RULES.DATE_RANGE_MAX_LENGTH,
        {
            message: `Date range cannot exceed ${DATE_RANGE_RULES.DATE_RANGE_MAX_LENGTH} days`,
            path: ["end"]
        }
    );

export const CampaignParamsSchema = z.object({
    id: z.string().uuid({ message: "Invalid campaign identifier" })
});

export const CampaignSchema = z.object({
    id: z.string(),
    userId: z.string(),
    end: z.string(),
    name: z.string(),
    start: z.string(),
    topics: z.array(z.string())
});
