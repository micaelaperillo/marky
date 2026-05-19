import type { Campaign } from "../campaign.types.js";

export interface SaveCampaignInput {
	userId: string;
	name: string;
	topics: string[];
	start: string;
	end: string;
}

export interface ICampaignRepository {
	findAll(userId: string): Promise<Campaign[]>;
	findOne(userId: string, name: string): Promise<Campaign | null>;
	save(input: SaveCampaignInput): Promise<void>;
}
