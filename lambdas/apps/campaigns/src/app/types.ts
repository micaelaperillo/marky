import type z from "zod";
import type { CampaignInputSchema, CampaignSchema } from "./validations";

export type Campaign = z.infer<typeof CampaignSchema>;
export type CampaignInput = z.infer<typeof CampaignInputSchema>;

export type CampaignEvent = {
    action: "create" | "delete";
    campaignId: string;
    topics: string[];
    startDate: string;
    endDate: string;
    rateMinutes?: number;
};
