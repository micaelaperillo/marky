import type { Campaign, CampaignInput } from "./campaign.types.js";
import type { ICampaignRepository } from "./interfaces/campaign.repository.js";
import type { ICampaignService } from "./interfaces/campaign.service.js";
import type { IReportRepository } from "../reports/interfaces/report.repository.js";

export class CampaignService implements ICampaignService {
	private campaignRepo: ICampaignRepository;
	private reportRepo: IReportRepository;

	constructor(campaignRepo: ICampaignRepository, reportRepo: IReportRepository) {
		this.campaignRepo = campaignRepo;
		this.reportRepo = reportRepo;
	}

	async list(userId: string): Promise<Campaign[]> {
		return this.campaignRepo.findAll(userId);
	}

	async get(userId: string, name: string): Promise<Campaign | null> {
		return this.campaignRepo.findOne(userId, name);
	}

	async create(userId: string, input: CampaignInput): Promise<void> {
		const { campaign, topics, start, end } = input;
		await this.campaignRepo.save({ end, name: campaign, start, topics, userId });
	}
}
