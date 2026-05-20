import z from "zod";

export const ReportSchema = z.object({
    campaignId: z.string(),
    timestamp: z.string().datetime(),
    sentiment: z.number().min(-1).max(1),
    report: z.record(z.string(), z.unknown())
});

export const SentimentPointSchema = z.object({
    timestamp: z.string().datetime(),
    sentiment: z.number().min(-1).max(1)
});
