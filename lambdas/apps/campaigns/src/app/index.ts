import { SqsCampaignsEnvSchema } from "@shared/config";
import { errorMiddleware } from "@shared/express/errors";
import * as validate from "@shared/express/validate";
import { getPool } from "@shared/service/postgres";
import * as sqs from "@shared/service/sqs";
import express from "express";

const env = SqsCampaignsEnvSchema.parse(process.env);

import { RdsCampaignRepository } from "./repository";
import type { CampaignEvent, CampaignInput } from "./types";
import {
	CampaignInputSchema,
	CampaignParamsSchema,
	CampaignQuerySchema,
} from "./validations";

const repo = new RdsCampaignRepository();

const app = express();

app.use(express.json());
app.use((req, res, next) => {
	const claims = (req as any).requestContext?.authorizer?.claims;
	if (!claims?.sub) {
		res.status(401).json({ error: "Unauthorized" });
		return;
	}
	res.locals.userId = claims.sub;
	next();
});

app
	.route("/")
	.get(async (req, res, next) => {
		try {
			const { status } = req.query as any;
			const [campaigns, stats] = await Promise.all([
				repo.findAll(res.locals.userId, status),
				repo.getStats(res.locals.userId),
			]);
			res.json({ campaigns, stats });
		} catch (err) {
			next(err);
		}
	})
	.post(validate.body(CampaignInputSchema), async (req, res, next) => {
		const pool = await getPool();
		const client = await pool.connect();
		try {
			const input = req.body as CampaignInput;
			const name = input.campaign.trim();

			await client.query("BEGIN");

			let id: string;
			try {
				id = await repo.saveWithClient(client, {
					...input,
					name,
					userId: res.locals.userId,
				});
			} catch (err: unknown) {
				await client.query("ROLLBACK");
				if (
					typeof err === "object" &&
					err !== null &&
					(err as { code?: string }).code === "23505"
				) {
					res.status(409).json({
						error: "You already have a campaign with that name",
					});
					return;
				}
				throw err;
			}

			await sqs.send({
				MessageBody: JSON.stringify({
					action: "create",
					campaignId: id,
					endDate: input.end,
					startDate: input.start,
					topics: input.topics,
					frequencyMin: input.frequencyMin,
				} satisfies CampaignEvent),
				MessageDeduplicationId: `create-${id}`,
				MessageGroupId: id,
				QueueUrl: env.sqs.campaigns,
			});

			await client.query("COMMIT");
			res.status(201).json({ id, name });
		} catch (err) {
			try {
				await client.query("ROLLBACK");
			} catch {
				// already rolled back
			}
			next(err);
		} finally {
			client.release();
		}
	});

app
	.route("/:id")
	.get(validate.params(CampaignParamsSchema), async (req, res, next) => {
		try {
			const campaign = await repo.findById(res.locals.userId, req.params.id);

			if (!campaign) {
				return res.status(404).json({ message: "Campaign not found" });
			}

			res.json(campaign);
		} catch (err) {
			next(err);
		}
	})
	.delete(validate.params(CampaignParamsSchema), async (req, res, next) => {
		try {
			const campaign = await repo.findById(res.locals.userId, req.params.id);

			if (!campaign) {
				return res.status(404).json({ message: "Campaign not found" });
			}

			await repo.delete(res.locals.userId, req.params.id);

			await sqs.send({
				MessageBody: JSON.stringify({
					action: "delete",
					campaignId: campaign.id,
				} satisfies Pick<CampaignEvent, "action" | "campaignId">),
				MessageDeduplicationId: `delete-${campaign.id}`,
				MessageGroupId: campaign.id,
				QueueUrl: env.sqs.campaigns,
			});

			res.status(204).end();
		} catch (err) {
			next(err);
		}
	});

app.use(errorMiddleware);

export default app;
