import type { SQSHandler, SQSRecord } from "aws-lambda";

import { analyze } from "./analyze.js";
import { getGeminiApiKey } from "./secrets.js";
import { publishReport } from "./sqs.js";
import type { InputMessage } from "./types.js";

function parseRecord(record: SQSRecord): InputMessage {
	let body: unknown;
	try {
		body = JSON.parse(record.body);
	} catch (err) {
		throw new Error(
			`SQS record ${record.messageId} body is not JSON: ${(err as Error).message}`,
			{ cause: err },
		);
	}

	const m = body as Partial<InputMessage>;
	if (
		!m.id ||
		!Array.isArray(m.topics) ||
		!Array.isArray(m.posts) ||
		!m.fetchedAt
	) {
		throw new Error(
			`SQS record ${record.messageId} missing required fields (id, topics, posts, fetchedAt)`,
		);
	}

	return m as InputMessage;
}

export const handler: SQSHandler = async (event) => {
	console.log(`Received ${event.Records.length} SQS record(s)`);

	const apiKey = await getGeminiApiKey();
	const failures: { itemIdentifier: string }[] = [];

	for (const record of event.Records) {
		try {
			const input = parseRecord(record);
			console.log(
				`Processing id=${input.id} topics="${input.topics}" posts=${input.posts.length}`,
			);

			const report = await analyze(apiKey, input);
			await publishReport(report);

			console.log(
				`Published id=${report.id} sentiment=${report.sentiment.label} (${report.sentiment.score})`,
			);
		} catch (err) {
			console.error(`Failed record ${record.messageId}:`, err);
			failures.push({ itemIdentifier: record.messageId });
		}
	}

	return { batchItemFailures: failures };
};
