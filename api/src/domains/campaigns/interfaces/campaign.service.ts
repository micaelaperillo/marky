import type { Campaign, CampaignInput } from "../campaign.types.js";

export interface ICampaignService {
	list(userId: string): Promise<Campaign[]>;
	get(userId: string, name: string): Promise<Campaign | null>;
	create(userId: string, input: CampaignInput): Promise<void>;
}
