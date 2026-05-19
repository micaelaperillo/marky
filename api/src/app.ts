import { ExpressAuthController } from "@domains/auth/auth.controller.express.js";
import { ExpressCampaignController } from "@domains/campaigns/campaign.controller.express.js";
import { CampaignService } from "@domains/campaigns/campaign.service.js";
import { DynamoCampaignRepository } from "@domains/campaigns/dynamo.repository.js";
import { env } from "@shared/config/env.js";
import { logger } from "@shared/logger.js";
import { errorMiddleware } from "@shared/middleware/error.js";
import express from "express";

export const app = express();

const {
	aws: { lambdaTask },
	dev: { port },
} = env;

app.use(express.json());

const authController = new ExpressAuthController();

const campaignRepo = new DynamoCampaignRepository();
const campaignService = new CampaignService(campaignRepo);
const campaignController = new ExpressCampaignController(campaignService);

app.use("/api/auth", authController.router);
app.use("/api/campaigns", campaignController.router);

app.get("/api/health", (_req, res) => {
	res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use(errorMiddleware);

if (!lambdaTask) {
	app.listen(port, () => logger.info({ port }, "API running"));
}
