import { SqsCampaignsEnvSchema } from "@shared/config";
import { errorMiddleware } from "@shared/express/errors";
import * as validate from "@shared/express/validate";
import { getPool } from "@shared/service/postgres";
import * as sqs from "@shared/service/sqs";
import express from "express";

const env = SqsCampaignsEnvSchema.parse(process.env);

import { RdsCampaignRepository } from "./repository";
import type { CampaignEvent, CampaignInput } from "./types";
import { CampaignInputSchema, CampaignParamsSchema } from "./validations";

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
	.get(async (_req, res, next) => {
		try {
			const campaigns = await repo.findAll(res.locals.userId);
			res.json(campaigns);
		} catch (err) {
			next(err);
		}
	})
	.post(validate.body(CampaignInputSchema), async (req, res, next) => {
		const pool = await getPool();
		const client = await pool.connect();
		try {
			const input = req.body as CampaignInput;

			await client.query("BEGIN");

			const id = await repo.saveWithClient(client, {
				...input,
				userId: res.locals.userId,
			});

			await sqs.send({
				MessageBody: JSON.stringify({
					action: "create",
					campaignId: id,
					endDate: input.end,
					startDate: input.start,
					topics: input.topics,
				} satisfies CampaignEvent),
				MessageDeduplicationId: `create-${id}`,
				MessageGroupId: id,
				QueueUrl: env.sqs.campaigns,
			});

			await client.query("COMMIT");
			res.status(201).json({ id });
		} catch (err) {
			await client.query("ROLLBACK");
			next(err);
		} finally {
			client.release();
		}
	});

app
	.route("/:name")
	.get(validate.params(CampaignParamsSchema), async (req, res, next) => {
		try {
			const campaign = await repo.findOne(res.locals.userId, req.params.name);

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
			const campaign = await repo.findOne(res.locals.userId, req.params.name);

			if (!campaign) {
				return res.status(404).json({ message: "Campaign not found" });
			}

			await repo.delete(res.locals.userId, req.params.name);

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
