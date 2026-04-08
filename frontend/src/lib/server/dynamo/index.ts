import type { Dayjs } from 'dayjs';

import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';
import { PutCommand, DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

import iso from '$lib/modules/iso';

const client = new DynamoDBClient({region: 'us-east-1'});
const docClient = DynamoDBDocumentClient.from(client);

//#region Tasks

export type Task = {
	// TaskDate
	Hash: string;
	// Topic#ReportDate
	Sort: string;
};

export function putTask(schedule: Dayjs, topic: string, date: Dayjs) {
	const command = new PutCommand({
		TableName: 'marky-data',
		Item: {
			Hash: `TASKS#${iso(schedule)}`,
			Sort: `${topic}#${iso(date)}`
		}
	});

	return docClient.send(command);
}

//#endregion

//#region Reports

export type Report = {
	/** Topic */
	Hash: string;
	/** Date */
	Sort: string;

	// TODO: decide what to store in the report
	[x: string]: string | number;
};

export function getReport(topic: string, date: Dayjs) {
	const command = new GetCommand({
		TableName: 'marky-data',
		Key: {
			Hash: `TOPIC#${topic}`,
			Sort: date.unix()
		}
	});

	return docClient.send(command);
}

export function getReports(topic: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		TableName: 'marky-data',
		KeyConditionExpression: 'Hash = :topic AND #date BETWEEN :start AND :end',
		ExpressionAttributeNames: {
			'#date': 'Sort'
		},
		ExpressionAttributeValues: {
			':topic': { S: `TOPIC#${topic}` },
			':start': { N: start.unix().toString() },
			':end': { N: end.unix().toString() }
		}
	});

	return docClient.send(command);
}

//#endregion

//#region Campaigns

export type Campaign = {
	/** UserId */
	Hash: string;
	/** CampaignName */
	Sort: string;
	Topics: string[];
	Start: string;
	End: string;
};

export function putCampaign(
	user: string,
	name: string,
	topics: string[],
	start: Dayjs,
	end: Dayjs
) {
	const command = new PutCommand({
		TableName: 'marky-data',
		Item: {
			Hash: user,
			Sort: name,
			Topics: topics,
			Start: iso(start),
			End: iso(end)
		}
	});

	return docClient.send(command);
}

export function getCampaign(user: string, name: string) {
	const command = new GetCommand({
		TableName: 'marky-data',
		Key: {
			Hash: user,
			Sort: name
		}
	});

	return docClient.send(command);
}

export function getCampaigns(user: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		TableName: 'marky-data',
		KeyConditionExpression: 'Hash = :user AND #date BETWEEN :start AND :END',
		ExpressionAttributeNames: {
			'#date': 'Date'
		},
		ExpressionAttributeValues: {
			':user': { S: user },
			':start': { N: start.unix().toString() },
			':end': { N: end.unix().toString() }
		}
	});

	return docClient.send(command);
}

export function getAllCampaigns(user: string) {
	const command = new QueryCommand({
		TableName: 'marky-data',
		KeyConditionExpression: 'Hash = :user',
		ExpressionAttributeValues: {
			':user': { S: user }
		}
	});

	return docClient.send(command);
}

//#endregion
