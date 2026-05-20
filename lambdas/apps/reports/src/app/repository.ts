import {
	type AttributeValue,
	GetItemCommand,
	QueryCommand,
} from "@aws-sdk/client-dynamodb";
import { unmarshall } from "@aws-sdk/util-dynamodb";
import { dynamo as dynamoClient, TABLE } from "@shared/service/dynamo";
import type { Report, SentimentPoint } from "./report.types";
import { ReportSchema, SentimentPointSchema } from "./report.validation";

export class DynamoReportRepository {
	async findOne(campaignId: string, timestamp: string): Promise<Report | null> {
		const command = new GetItemCommand({
			Key: {
				PK: { S: this.pk(campaignId) },
				SK: { S: this.reportSk(timestamp) },
			},
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);

		if (!result.Item) return null;

		return this.unmarshallReport(result.Item);
	}

	async findLatestByCampaignId(campaignId: string): Promise<Report | null> {
		const command = new QueryCommand({
			ExpressionAttributeValues: {
				":pk": { S: this.pk(campaignId) },
				":reportPrefix": { S: "REPORT#" },
			},
			KeyConditionExpression: "PK = :pk AND begins_with(SK, :reportPrefix)",
			Limit: 1,
			ScanIndexForward: false,
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);

		if (!result.Items || result.Items.length === 0) return null;

		return this.unmarshallReport(result.Items[0]);
	}

	async findReportsByCampaignIdBetween(
		campaignId: string,
		start: string,
		end: string,
	): Promise<Report[]> {
		const command = new QueryCommand({
			ExpressionAttributeValues: {
				":end": { S: this.reportSk(end) },
				":pk": { S: this.pk(campaignId) },
				":start": { S: this.reportSk(start) },
			},
			KeyConditionExpression: "PK = :pk AND SK BETWEEN :start AND :end",
			ScanIndexForward: true,
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);

		return (result.Items ?? []).map(this.unmarshallReport);
	}

	async findSentimentPointsByCampaignIdBetween(
		campaignId: string,
		start: string,
		end: string,
	): Promise<SentimentPoint[]> {
		const command = new QueryCommand({
			ExpressionAttributeValues: {
				":end": { S: this.reportSk(end) },
				":pk": { S: this.pk(campaignId) },
				":start": { S: this.reportSk(start) },
			},
			KeyConditionExpression: "PK = :pk AND SK BETWEEN :start AND :end",
			ProjectionExpression: "SK, sentiment",
			ScanIndexForward: true,
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);

		return (result.Items ?? []).map(this.unmarshallSentimentPoint);
	}

	async findLatestSentimentPointsByCampaignId(
		campaignId: string,
		limit: number,
	): Promise<SentimentPoint[]> {
		const command = new QueryCommand({
			ExpressionAttributeValues: {
				":pk": { S: this.pk(campaignId) },
				":reportPrefix": { S: "REPORT#" },
			},
			KeyConditionExpression: "PK = :pk AND begins_with(SK, :reportPrefix)",
			Limit: limit,
			ProjectionExpression: "SK, sentiment",
			ScanIndexForward: false,
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);

		return (result.Items ?? []).map(this.unmarshallSentimentPoint);
	}

	private pk(campaignId: string): string {
		return `CAMPAIGN#${campaignId}`;
	}

	private reportSk(timestamp: string): string {
		return `REPORT#${timestamp}`;
	}

	private unmarshallReport(item: Record<string, AttributeValue>): Report {
		const data = unmarshall(item);
		return ReportSchema.parse({
			campaignId: data.PK.replace("CAMPAIGN#", ""),
			report: data.report,
			sentiment: data.sentiment,
			timestamp: data.SK.replace("REPORT#", ""),
		});
	}

	private unmarshallSentimentPoint(
		item: Record<string, AttributeValue>,
	): SentimentPoint {
		const data = unmarshall(item);
		return SentimentPointSchema.parse({
			sentiment: data.sentiment,
			timestamp: data.SK.replace("REPORT#", ""),
		});
	}
}
