import type z from "zod";
import type {
    ReportSchema,
    SentimentPointSchema
} from "./report.validation.js";

export type Report = z.infer<typeof ReportSchema>;
export type SentimentPoint = z.infer<typeof SentimentPointSchema>;
