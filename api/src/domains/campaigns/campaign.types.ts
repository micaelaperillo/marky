import type z from "zod";
import type {
	CampaignInputSchema,
	CampaignSchema,
} from "./campaign.validation.js";

export type Campaign = z.infer<typeof CampaignSchema>;
export type CampaignInput = z.infer<typeof CampaignInputSchema>;
