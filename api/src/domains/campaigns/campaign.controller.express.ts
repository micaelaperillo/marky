import { requireAuth } from "@shared/middleware/auth.js";
import { validateBody, validateParams } from "@shared/middleware/validate.js";
import type { NextFunction, Request, Response } from "express";
import { Router } from "express";
import {
	CampaignInputSchema,
	CampaignParamsSchema,
} from "./campaign.validation.js";
import type { ICampaignService } from "./interfaces/campaign.service.js";

export class ExpressCampaignController {
	readonly router: Router;
	private service: ICampaignService;

	constructor(service: ICampaignService) {
		this.service = service;
		this.router = Router();
		this.router.use(requireAuth);
		this.router.get("/", this.list.bind(this));
		this.router.get(
			"/:name",
			validateParams(CampaignParamsSchema),
			this.get.bind(this),
		);
		this.router.post(
			"/",
			validateBody(CampaignInputSchema),
			this.create.bind(this),
		);
	}

	async list(_req: Request, res: Response, next: NextFunction): Promise<void> {
		try {
			const campaigns = await this.service.list(res.locals.userId);
			res.json(campaigns);
		} catch (err) {
			next(err);
		}
	}

	async get(req: Request, res: Response, next: NextFunction): Promise<void> {
		try {
			const campaign = await this.service.get(
				res.locals.userId,
				req.params.name,
			);
			if (!campaign) {
				res.status(404).json({ error: "Campaign not found" });
				return;
			}
			res.json(campaign);
		} catch (err) {
			next(err);
		}
	}

	async create(req: Request, res: Response, next: NextFunction): Promise<void> {
		try {
			await this.service.create(res.locals.userId, req.body);
			res.status(201).json({ success: true });
		} catch (err) {
			next(err);
		}
	}
}
