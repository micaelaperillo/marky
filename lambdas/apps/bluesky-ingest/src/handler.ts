import { PublishCommand, SNSClient } from "@aws-sdk/client-sns";
import type { SQSBatchResponse, SQSEvent } from "aws-lambda";

import { searchBlueSky } from "./bluesky";

const sns = new SNSClient({ region: process.env.AWS_REGION });

interface SchedulerInput {
	id: string;
	topics: string[];
}

function isSQSEvent(event: unknown): event is SQSEvent {
	return (
		typeof event === "object" &&
		event !== null &&
		"Records" in event &&
		Array.isArray((event as SQSEvent).Records)
	);
}

async function processCampaign(campaign: { id: string; topics: string[] }) {
	const result = await searchBlueSky(campaign);
	await sns.send(
		new PublishCommand({
			Message: JSON.stringify(result),
			MessageGroupId: result.id,
			TopicArn: process.env.SNS_TOPIC_ARN,
		}),
	);
}

export const handler = async (
	event: SQSEvent | SchedulerInput,
): Promise<SQSBatchResponse | void> => {
	if (!isSQSEvent(event)) {
		await processCampaign({ id: event.id, topics: event.topics });
		return;
	}

	const failures: { itemIdentifier: string }[] = [];

	for (const record of event.Records) {
		try {
			const raw = JSON.parse(record.body);
			if (!raw.id || !Array.isArray(raw.topics) || raw.topics.length === 0) {
				throw new Error("Invalid campaign message: missing id or topics");
			}
			const campaign = { id: raw.id as string, topics: raw.topics as string[] };
			await processCampaign(campaign);
		} catch (err) {
			console.error("Failed record", record.messageId, err);
			failures.push({ itemIdentifier: record.messageId });
		}
	}

	return { batchItemFailures: failures };
};
