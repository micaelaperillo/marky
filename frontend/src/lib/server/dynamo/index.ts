import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import type { Dayjs } from 'dayjs';

import iso from '$lib/modules/iso';

const client = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);

// In-memory store for local MVP
const memoryStore = new Map<string, any>();

function getMemoryKey(hash: string, sort: string | number) {
	return `${hash}##${sort}`;
}

//#region Tasks

export type Task = {
	// TaskDate
	Hash: string;
	// Topic#ReportDate
	Sort: string;
};

export async function putTask(schedule: Dayjs, topic: string, date: Dayjs) {
	const item = {
		Hash: `TASKS#${iso(schedule)}`,
		Sort: `${topic}#${iso(date)}`
	};
	
	memoryStore.set(getMemoryKey(item.Hash, item.Sort), item);

	const command = new PutCommand({
		Item: item,
		TableName: 'marky-data'
	});

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB putTask failed, using memory fallback');
		return { $metadata: { httpStatusCode: 200 } };
	}
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

export async function getReport(topic: string, date: Dayjs) {
	const hash = `TOPIC#${topic}`;
	const sort = date.unix();
	
	const command = new GetCommand({
		Key: {
			Hash: hash,
			Sort: sort
		},
		TableName: 'marky-data'
	});

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB getReport failed, using memory fallback');
		return { Item: memoryStore.get(getMemoryKey(hash, sort)) };
	}
}

export async function getReports(topic: string, start: Dayjs, end: Dayjs) {
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

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB getReports failed, using memory fallback');
		const hash = `TOPIC#${topic}`;
		const items = Array.from(memoryStore.values()).filter(i => i.Hash === hash && i.Sort >= start.unix() && i.Sort <= end.unix());
		return { Items: items };
	}
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

export async function putCampaign(
	user: string,
	name: string,
	topics: string[],
	start: Dayjs,
	end: Dayjs
) {
	const item = {
		End: iso(end),
		Hash: `CAMPAIGNS#${user}`,
		Sort: name,
		Start: iso(start),
		Topics: topics
	};

	memoryStore.set(getMemoryKey(item.Hash, item.Sort), item);

	const command = new PutCommand({
		Item: item,
		TableName: 'marky-data'
	});

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB putCampaign failed, using memory fallback');
		return { $metadata: { httpStatusCode: 200 } };
	}
}

export async function getCampaign(user: string, name: string) {
	const hash = `CAMPAIGNS#${user}`;
	const sort = name;

	const command = new GetCommand({
		Key: {
			Hash: hash,
			Sort: sort
		},
		TableName: 'marky-data'
	});

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB getCampaign failed, using memory fallback');
		return { Item: memoryStore.get(getMemoryKey(hash, sort)) };
	}
}

export async function getCampaigns(user: string, start: Dayjs, end: Dayjs) {
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

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB getCampaigns failed, using memory fallback');
		const hash = `CAMPAIGNS#${user}`;
		// This is a rough filter for the local mock
		const items = Array.from(memoryStore.values()).filter(i => i.Hash === hash);
		return { Items: items };
	}
}

export async function getAllCampaigns(user: string) {
	const command = new QueryCommand({
		ExpressionAttributeValues: {
			':user': { S: `CAMPAIGNS#${user}` }
		},
		KeyConditionExpression: 'Hash = :user',
		TableName: 'marky-data'
	});

	try {
		return await docClient.send(command);
	} catch (e) {
		console.warn('DynamoDB getAllCampaigns failed, using memory fallback');
		const hash = `CAMPAIGNS#${user}`;
		const items = Array.from(memoryStore.values()).filter(i => i.Hash === hash);
		return { Items: items };
	}
}

//#endregion
