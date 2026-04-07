import type { Dayjs } from 'dayjs';

import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';
import { PutCommand, DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

import iso from '$lib/modules/iso';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

//#region Tasks

export type Task = {
	// Hash
	TaskDate: string;
	// Sort
	Topic: string;
	ReportDate: string;
};

export function putTask(schedule: Dayjs, topic: string, date: Dayjs) {
	const command = new PutCommand({
		TableName: 'marky-tasks',
		Item: {
			TaskDate: iso(schedule),
			Topic: topic,
			ReportDate: iso(date)
		}
	});

	return docClient.send(command);
}

//#endregion

//#region Reports

export type Report = {
	// Hash
	Topic: string;
	// Sort
	Date: string;
	// TODO: decide what to store in the report
	[x: string]: string | number;
};

export function getReport(topic: string, date: Dayjs) {
	const command = new GetCommand({
		TableName: 'marky-reports',
		Key: {
			Topic: topic,
			Date: date.unix()
		}
	});

	return docClient.send(command);
}

export function getReports(topic: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		TableName: 'marky-reports',
		KeyConditionExpression: 'Topic = :topic AND #date BETWEEN :start AND :end',
		ExpressionAttributeNames: {
			'#date': 'Date'
		},
		ExpressionAttributeValues: {
			':topic': { S: topic },
			':start': { N: start.unix().toString() },
			':end': { N: end.unix().toString() }
		}
	});

	return docClient.send(command);
}

//#endregion

//#region Campaigns

export type Campaign = {
	// Hash
	UserId: string;
	// Sort
	CampaignName: string;
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
		TableName: 'marky-campaign',
		Item: {
			UserId: user,
			CampaignName: name,
			Topics: topics,
			Start: iso(start),
			End: iso(end)
		}
	});

	return docClient.send(command);
}

export function getCampaign(user: string, name: string) {
	const command = new GetCommand({
		TableName: 'marky-campaigns',
		Key: {
			UserId: user,
			CampaignName: name
		}
	});

	return docClient.send(command);
}

export function getCampaigns(user: string, start: Dayjs, end: Dayjs) {
	const command = new QueryCommand({
		TableName: 'marky-campaigns',
		KeyConditionExpression: 'UserId = :user AND #date BETWEEN :start AND :END',
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
		TableName: 'marky-campaigns',
		KeyConditionExpression: 'UserId = :user',
		ExpressionAttributeValues: {
			':user': { S: user }
		}
	});

	return docClient.send(command);
}

//#endregion
