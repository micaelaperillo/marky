import type { ITaskService } from "@domains/tasks/interfaces/task.service.js";
import type { Campaign, CampaignInput } from "./campaign.types.js";
import type { ICampaignRepository } from "./interfaces/campaign.repository.js";
import type { ICampaignService } from "./interfaces/campaign.service.js";

export class CampaignService implements ICampaignService {
	private repo: ICampaignRepository;
	private taskService: ITaskService;

	constructor(repo: ICampaignRepository, taskService: ITaskService) {
		this.repo = repo;
		this.taskService = taskService;
	}

	async list(userId: string): Promise<Campaign[]> {
		return this.repo.findAll(userId);
	}

	async get(userId: string, name: string): Promise<Campaign | null> {
		return this.repo.findOne(userId, name);
	}

	async create(userId: string, input: CampaignInput): Promise<void> {
		const { campaign, topics, start, end } = input;
		await this.taskService.createForDateRange(topics, start, end);
		await this.repo.save({ end, name: campaign, start, topics, userId });
	}
}
