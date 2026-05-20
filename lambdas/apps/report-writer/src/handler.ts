import { marshall } from "@aws-sdk/util-dynamodb";
import * as dynamo from "@shared/service/dynamo";
import type { SQSBatchResponse, SQSHandler } from "aws-lambda";

export const handler: SQSHandler = async (event) => {
	const failures: SQSBatchResponse["batchItemFailures"] = [];

	for (const record of event.Records) {
		try {
			await dynamo.put({
				Item: mapper(JSON.parse(record.body)),
				TableName: dynamo.TABLE,
			});
		} catch (err) {
			console.error(`Failed to store record ${record.messageId}:`, err);
			failures.push({ itemIdentifier: record.messageId });
		}
	}

	return { batchItemFailures: failures };
};

function mapper(data: {
	id: string;
	fetchedAt: string;
	sentiment: {
		score: number;
	};
	[k: string]: unknown;
}) {
	const row: Record<string, unknown> = {
		campaign_id: data.id,
		PK: `CAMPAIGN#${data.id}`,

		report: data,
		SK: `REPORT#${data.fetchedAt}`,
		sentiment: data.sentiment.score,
		timestamp: data.fetchedAt,
	};

	return marshall(row);
}
