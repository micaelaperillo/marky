import { env } from "@shared/config/env.js";
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
		this.router.post(
			"/:name/analyze",
			validateParams(CampaignParamsSchema),
			this.analyze.bind(this),
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

	async analyze(
		req: Request,
		res: Response,
		next: NextFunction,
	): Promise<void> {
		try {
			const campaign = await this.service.get(
				res.locals.userId,
				req.params.name,
			);
			if (!campaign) {
				res.status(404).json({ error: "Campaign not found" });
				return;
			}
			if (!campaign.topics.length) {
				res.status(400).json({ error: "Campaign has no topics to analyze." });
				return;
			}

			const url = new URL("/api/analyze", env.backendUrl);
			url.searchParams.set("start", campaign.start);
			url.searchParams.set("end", campaign.end);
			url.searchParams.set("topics", campaign.topics.join(","));

			const controller = new AbortController();
			const timeout = setTimeout(() => controller.abort(), 30_000);

			const resp = await fetch(url, { signal: controller.signal }).finally(
				() => clearTimeout(timeout),
			);

			if (!resp.ok) {
				res
					.status(502)
					.json({ error: "Analysis service returned an error." });
				return;
			}

			let data: unknown;
			try {
				data = await resp.json();
			} catch {
				res
					.status(502)
					.json({ error: "Analysis service returned an invalid response." });
				return;
			}

			const report =
				data && typeof data === "object" && "report" in data
					? (data as { report: unknown }).report
					: undefined;

			if (typeof report !== "string") {
				res
					.status(502)
					.json({ error: "Analysis service returned an invalid response." });
				return;
			}

			res.json({ report });
		} catch (err) {
			if (err instanceof Error && err.name === "AbortError") {
				res.status(504).json({ error: "Analysis timed out." });
				return;
			}
			next(err);
		}
	}
}
