import {
    AttributeValue,
    GetItemCommand,
    QueryCommand
} from "@aws-sdk/client-dynamodb";
import { unmarshall } from "@aws-sdk/util-dynamodb";
import { dynamo as dynamoClient, TABLE } from "@shared/service/dynamo";
import { Report, SentimentPoint } from "./report.types";
import { ReportSchema, SentimentPointSchema } from "./report.validation";

export class DynamoReportRepository {
    async findOne(
        campaignId: string,
        timestamp: string
    ): Promise<Report | null> {
        const command = new GetItemCommand({
            TableName: TABLE,
            Key: {
                PK: { S: this.pk(campaignId) },
                SK: { S: this.reportSk(timestamp) }
            }
        });

        const result = await dynamoClient.send(command);

        if (!result.Item) return null;

        return this.unmarshallReport(result.Item);
    }

    async findLatestByCampaignId(campaignId: string): Promise<Report | null> {
        const command = new QueryCommand({
            TableName: TABLE,
            KeyConditionExpression:
                "PK = :pk AND begins_with(SK, :reportPrefix)",
            ExpressionAttributeValues: {
                ":pk": { S: this.pk(campaignId) },
                ":reportPrefix": { S: "REPORT#" }
            },
            ScanIndexForward: false,
            Limit: 1
        });
        console.log("Executing " + campaignId +" query: ",command);

        const result = await dynamoClient.send(command);

        if (!result.Items || result.Items.length === 0) return null;

        return this.unmarshallReport(result.Items[0]);
    }

    async findReportsByCampaignIdBetween(
        campaignId: string,
        start: string,
        end: string
    ): Promise<Report[]> {
        const command = new QueryCommand({
            TableName: TABLE,
            KeyConditionExpression: "PK = :pk AND SK BETWEEN :start AND :end",
            ExpressionAttributeValues: {
                ":pk": { S: this.pk(campaignId) },
                ":start": { S: this.reportSk(start) },
                ":end": { S: this.reportSk(end) }
            },
            ScanIndexForward: true
        });

        const result = await dynamoClient.send(command);

        return (result.Items ?? []).map(this.unmarshallReport);
    }

    async findSentimentPointsByCampaignIdBetween(
        campaignId: string,
        start: string,
        end: string
    ): Promise<SentimentPoint[]> {
        const command = new QueryCommand({
            TableName: TABLE,
            KeyConditionExpression: "PK = :pk AND SK BETWEEN :start AND :end",
            ProjectionExpression: "SK, sentiment",
            ExpressionAttributeValues: {
                ":pk": { S: this.pk(campaignId) },
                ":start": { S: this.reportSk(start) },
                ":end": { S: this.reportSk(end) }
            },
            ScanIndexForward: true
        });

        const result = await dynamoClient.send(command);

        return (result.Items ?? []).map(this.unmarshallSentimentPoint);
    }

    async findLatestSentimentPointsByCampaignId(
        campaignId: string,
        limit: number
    ): Promise<SentimentPoint[]> {
        const command = new QueryCommand({
            TableName: TABLE,
            KeyConditionExpression: "PK = :pk AND begins_with(SK, :reportPrefix)",
            ProjectionExpression: "SK, sentiment",
            ExpressionAttributeValues: {
                ":pk": { S: this.pk(campaignId) },
                ":reportPrefix": { S: "REPORT#" }
            },
            ScanIndexForward: false,
            Limit: limit
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
        console.log("Unmarshalling item: ", item);
        const data = unmarshall(item); 
        return ReportSchema.parse({
            campaignId: data.PK.replace("CAMPAIGN#", ""),
            timestamp: data.SK.replace("REPORT#", ""),
            sentiment: data.sentiment,
            report: data.report
        });
    }

    private unmarshallSentimentPoint(
        item: Record<string, AttributeValue>
    ): SentimentPoint {
        const data = unmarshall(item);
        return SentimentPointSchema.parse({
            timestamp: data.SK.replace("REPORT#", ""),
            sentiment: data.sentiment,
        });
    }
}
