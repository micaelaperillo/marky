import type { AttributeValue } from "@aws-sdk/client-dynamodb";
import {
	ConditionalCheckFailedException,
	GetItemCommand,
	PutItemCommand,
	QueryCommand,
} from "@aws-sdk/client-dynamodb";
import { dynamoClient, TABLE } from "@shared/database/dynamo.client.js";
import { ApiError } from "@shared/errors.js";
import type { Campaign } from "./campaign.types.js";
import { CampaignSchema } from "./campaign.validation.js";
import type {
	ICampaignRepository,
	SaveCampaignInput,
} from "./interfaces/campaign.repository.js";

export class DynamoCampaignRepository implements ICampaignRepository {
	async findAll(userId: string): Promise<Campaign[]> {
		const command = new QueryCommand({
			ExpressionAttributeValues: {
				":user": { S: `CAMPAIGNS#${userId}` },
			},
			KeyConditionExpression: "PK = :user",
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);
		return (result.Items ?? []).map((item) => this.unmarshall(item));
	}

	async findOne(userId: string, name: string): Promise<Campaign | null> {
		const command = new GetItemCommand({
			Key: {
				PK: { S: `CAMPAIGNS#${userId}` },
				SK: { S: name },
			},
			TableName: TABLE,
		});

		const result = await dynamoClient.send(command);
		if (!result.Item) return null;
		return this.unmarshall(result.Item);
	}

	async save({
		userId,
		name,
		topics,
		start,
		end,
	}: SaveCampaignInput): Promise<void> {
		const command = new PutItemCommand({
			ConditionExpression: "attribute_not_exists(PK)",
			Item: {
				End: { S: end },
				PK: { S: `CAMPAIGNS#${userId}` },
				SK: { S: name },
				Start: { S: start },
				Topics: { SS: topics },
			},
			TableName: TABLE,
		});

		try {
			await dynamoClient.send(command);
		} catch (err) {
			if (err instanceof ConditionalCheckFailedException) {
				throw new CampaignAlreadyExistsError(name);
			}
			throw err;
		}
	}

	private unmarshall(item: Record<string, AttributeValue>): Campaign {
		return CampaignSchema.parse({
			end: item.End?.S ?? "",
			name: item.SK?.S ?? "",
			start: item.Start?.S ?? "",
			topics: item.Topics?.SS ?? item.Topics?.L?.map((t) => t.S ?? "") ?? [],
		});
	}
}

export class CampaignAlreadyExistsError extends ApiError {
	get statusCode() {
		return 409;
	}

	constructor(name: string) {
		super(`Campaign "${name}" already exists`);
	}
}
