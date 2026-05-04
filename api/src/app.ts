import { ExpressAuthController } from "@domains/auth/auth.controller.express.js";
import { AuthService } from "@domains/auth/auth.service.js";
import { ExpressCampaignController } from "@domains/campaigns/campaign.controller.express.js";
import { CampaignService } from "@domains/campaigns/campaign.service.js";
import { DynamoCampaignRepository } from "@domains/campaigns/dynamo.repository.js";
import { DynamoTaskRepository } from "@domains/tasks/dynamo.repository.js";
import { TaskService } from "@domains/tasks/task.service.js";
import { env } from "@shared/config/env.js";
import { logger } from "@shared/logger.js";
import { errorMiddleware } from "@shared/middleware/error.js";
import cookieParser from "cookie-parser";
import express from "express";

export const app = express();

const {
	express: { cookieSecret },
	aws: { lambdaTask },
	dev: { port },
} = env;

app.use(express.json());
app.use(cookieParser(cookieSecret));

const authService = new AuthService();
const authController = new ExpressAuthController(authService);

const taskRepo = new DynamoTaskRepository();
const taskService = new TaskService(taskRepo);
const campaignRepo = new DynamoCampaignRepository();
const campaignService = new CampaignService(campaignRepo, taskService);
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
