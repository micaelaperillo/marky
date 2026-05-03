import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
	DynamoDBDocumentClient,
	GetCommand,
	PutCommand,
	QueryCommand,
} from "@aws-sdk/lib-dynamodb";
import type { Dayjs } from "dayjs";
import { env } from "$env/dynamic/private";

import iso from "$lib/modules/iso";

const TABLE_NAME = env.MARKY_DYNAMO_DATA_TABLE ?? "marky-data";

const client = new DynamoDBClient({ region: env.AWS_REGION ?? "us-east-1" });
const docClient = DynamoDBDocumentClient.from(client);

//#region Tasks

export type Task = {
	PK: string;
	SK: string;
};

export async function putTask(schedule: Dayjs, topic: string, date: Dayjs) {
	const command = new PutCommand({
		Item: {
			PK: `TASKS#${iso(schedule)}`,
			SK: `${topic}#${iso(date)}`,
		},
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

//#endregion

//#region Reports

export type Report = {
	PK: string;
	SK: string;
	[x: string]: string | number;
};

export async function getReport(topic: string, date: Dayjs) {
	const command = new GetCommand({
		Key: {
			PK: `TOPIC#${topic}`,
			SK: String(date.unix()),
		},
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

export async function getReports(topic: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		ExpressionAttributeNames: {
			"#sk": "SK",
		},
		ExpressionAttributeValues: {
			":end": String(end.unix()),
			":start": String(start.unix()),
			":topic": `TOPIC#${topic}`,
		},
		KeyConditionExpression: "PK = :topic AND #sk BETWEEN :start AND :end",
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

//#endregion

//#region Campaigns

export type Campaign = {
	PK: string;
	SK: string;
	Topics: string[];
	Start: string;
	End: string;
};

export async function putCampaign(
	user: string,
	name: string,
	topics: string[],
	start: Dayjs,
	end: Dayjs,
) {
	const command = new PutCommand({
		Item: {
			End: iso(end),
			PK: `CAMPAIGNS#${user}`,
			SK: name,
			Start: iso(start),
			Topics: topics,
		},
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

export async function getCampaign(user: string, name: string) {
	const command = new GetCommand({
		Key: {
			PK: `CAMPAIGNS#${user}`,
			SK: name,
		},
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

export async function getCampaigns(user: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		ExpressionAttributeNames: {
			"#end": "End",
			"#start": "Start",
		},
		ExpressionAttributeValues: {
			":end": iso(end),
			":start": iso(start),
			":user": `CAMPAIGNS#${user}`,
		},
		FilterExpression: "#start >= :start AND #end <= :end",
		KeyConditionExpression: "PK = :user",
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

export async function getAllCampaigns(user: string) {
	const command = new QueryCommand({
		ExpressionAttributeValues: {
			":user": `CAMPAIGNS#${user}`,
		},
		KeyConditionExpression: "PK = :user",
		TableName: TABLE_NAME,
	});

	return docClient.send(command);
}

//#endregion
