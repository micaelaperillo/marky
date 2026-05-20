import { errorMiddleware } from "@shared/express/errors";
import { authenticated } from "@shared/service/cognito";
import express from "express";
import { DynamoReportRepository } from "./repository";

const repo = new DynamoReportRepository();
const app = express();

app.use(express.json());
app.use(authenticated);

app.route("/latest").get(async (req, res, next) => {
	try {
		const { campaignId } = req.query;
		if (typeof campaignId !== "string") {
			return res.status(400).json({
				message: "campaignId query parameter is required and must be a string",
			});
		}
		const report = await repo.findLatestByCampaignId(campaignId);
		if (!report) {
			return res.status(404).json({ message: "Report not found" });
		}
		res.json(report);
	} catch (error) {
		next(error);
	}
});

app.route("/").get(async (req, res, next) => {
	try {
		const { campaignId, timestamp } = req.query;

		if (typeof campaignId !== "string") {
			return res.status(400).json({
				message: "campaignId query parameter is required and must be a string",
			});
		}

		if (typeof timestamp !== "string") {
			return res.status(400).json({
				message: "timestamp query parameter is required and must be a string",
			});
		}

		const report = await repo.findOne(campaignId, timestamp);

		if (!report) {
			return res.status(404).json({ message: "Report not found" });
		}

		return res.json(report);
	} catch (error) {
		next(error);
	}
});

app.route("/range").get(async (req, res, next) => {
	try {
		const { campaignId, start, end } = req.query;

		if (typeof campaignId !== "string") {
			return res.status(400).json({
				message: "campaignId query parameter is required and must be a string",
			});
		}

		if (typeof start !== "string") {
			return res.status(400).json({
				message: "start query parameter is required and must be a string",
			});
		}

		if (typeof end !== "string") {
			return res.status(400).json({
				message: "end query parameter is required and must be a string",
			});
		}

		const reports = await repo.findReportsByCampaignIdBetween(
			campaignId,
			start,
			end,
		);

		return res.json(reports);
	} catch (error) {
		next(error);
	}
});

app.route("/sentiment").get(async (req, res, next) => {
	try {
		const { campaignId, start, end } = req.query;

		if (typeof campaignId !== "string") {
			return res.status(400).json({
				message: "campaignId query parameter is required and must be a string",
			});
		}

		if (typeof start !== "string") {
			return res.status(400).json({
				message: "start query parameter is required and must be a string",
			});
		}

		if (typeof end !== "string") {
			return res.status(400).json({
				message: "end query parameter is required and must be a string",
			});
		}

		const points = await repo.findSentimentPointsByCampaignIdBetween(
			campaignId,
			start,
			end,
		);

		return res.json(points);
	} catch (error) {
		next(error);
	}
});

app.route("/sentiment/latest").get(async (req, res, next) => {
	try {
		const { campaignId, limit } = req.query;

		if (typeof campaignId !== "string") {
			return res.status(400).json({
				message: "campaignId query parameter is required and must be a string",
			});
		}

		if (typeof limit !== "string" || isNaN(Number(limit))) {
			return res.status(400).json({
				message: "limit query parameter is required and must be a number",
			});
		}

		const points = await repo.findLatestSentimentPointsByCampaignId(
			campaignId,
			Math.min(parseInt(limit), 100),
		);

		return res.json(points);
	} catch (error) {
		next(error);
	}
});

app.use(errorMiddleware);

export default app;
