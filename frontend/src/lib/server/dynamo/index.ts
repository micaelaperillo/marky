import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import type { Dayjs } from 'dayjs';

import iso from '$lib/modules/iso';

const client = new DynamoDBClient({ region: 'us-east-1' });
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
		Item: {
			Hash: `TASKS#${iso(schedule)}`,
			Sort: `${topic}#${iso(date)}`
		},
		TableName: 'marky-data'
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
		Key: {
			Hash: `TOPIC#${topic}`,
			Sort: date.unix()
		},
		TableName: 'marky-data'
	});

	return docClient.send(command);
}

export function getReports(topic: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		ExpressionAttributeNames: {
			'#date': 'Sort'
		},
		ExpressionAttributeValues: {
			':end': { N: end.unix().toString() },
			':start': { N: start.unix().toString() },
			':topic': { S: `TOPIC#${topic}` }
		},
		KeyConditionExpression: 'Hash = :topic AND #date BETWEEN :start AND :end',
		TableName: 'marky-data'
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
		Item: {
			End: iso(end),
			Hash: `CAMPAIGNS#${user}`,
			Sort: name,
			Start: iso(start),
			Topics: topics
		},
		TableName: 'marky-data'
	});

	return docClient.send(command);
}

export function getCampaign(user: string, name: string) {
	const command = new GetCommand({
		Key: {
			Hash: `CAMPAIGNS#${user}`,
			Sort: name
		},
		TableName: 'marky-data'
	});

	return docClient.send(command);
}

export function getCampaigns(user: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		ExpressionAttributeNames: {
			'#date': 'Date'
		},
		ExpressionAttributeValues: {
			':end': { N: end.unix().toString() },
			':start': { N: start.unix().toString() },
			':user': { S: `CAMPAIGNS#${user}` }
		},
		KeyConditionExpression: 'Hash = :user AND #date BETWEEN :start AND :END',
		TableName: 'marky-data'
	});

	return docClient.send(command);
}

export function getAllCampaigns(user: string) {
	const command = new QueryCommand({
		ExpressionAttributeValues: {
			':user': { S: `CAMPAIGNS#${user}` }
		},
		KeyConditionExpression: 'Hash = :user',
		TableName: 'marky-data'
	});

	return docClient.send(command);
}

//#endregion
