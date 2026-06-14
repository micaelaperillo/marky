import z from "zod";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import customParseFormat from "dayjs/plugin/customParseFormat.js";

dayjs.extend(utc);
dayjs.extend(customParseFormat);

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
            .refine((s) => dayjs(s, "YYYY-MM-DD", true).isValid(), {
                message: "Start date must be in YYYY-MM-DD format"
            }),
        end: z
            .string()
            .refine((s) => dayjs(s, "YYYY-MM-DD", true).isValid(), {
                message: "End date must be in YYYY-MM-DD format"
            }),
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
            const todayUtc = dayjs.utc().startOf("day");
            const startDateUtc = dayjs.utc(start).startOf("day");

            return !startDateUtc.isBefore(todayUtc);
        },
        {
            message: "Start date cannot be in the past",
            path: ["start"]
        }
    )
    // Date range is [start, end) - end date is exclusive
    .refine(
        ({ start, end }) => {
            const s = dayjs(start);
            const e = dayjs(end);
            return s.isBefore(e);
        },
        {
            message: "End date must be after start date",
            path: ["end"]
        }
    )
    .refine(
        ({ start, end }) => {
            const s = dayjs(start);
            const e = dayjs(end);
            return e.diff(s, "day") <= DATE_RANGE_RULES.DATE_RANGE_MAX_LENGTH;
        },
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
