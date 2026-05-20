import {
	CreateScheduleCommand,
	DeleteScheduleCommand,
	SchedulerClient,
} from "@aws-sdk/client-scheduler";
import * as sqs from "@shared/service/sqs";
import type { SQSBatchResponse, SQSHandler } from "aws-lambda";

const scheduler = new SchedulerClient();

const {
	CAMPAIGN_TOPICS_QUEUE_URL,
	SCHEDULE_GROUP_NAME,
	SCHEDULER_ROLE_ARN,
	SCHEDULER_LAMBDA_ARN,
} = process.env;

interface CampaignEvent {
	action: "create" | "delete";
	campaignId: string;
	topics: string[];
	startDate: string;
	endDate: string;
	rateMinutes?: number;
}

export const handler: SQSHandler = async (event) => {
	const failures: SQSBatchResponse["batchItemFailures"] = [];

	for (const record of event.Records) {
		try {
			const message: CampaignEvent = JSON.parse(record.body);
			const { action, campaignId } = message;

			if (action === "create") {
				await createSchedule(message);
				await enqueueInitialFetch(campaignId, message.topics);
			} else if (action === "delete") {
				await deleteSchedule(campaignId);
			} else {
				console.error(`Unknown action: ${action}`);
			}
		} catch (err) {
			console.error(`Failed to process record ${record.messageId}:`, err);
			failures.push({ itemIdentifier: record.messageId });
		}
	}

	return { batchItemFailures: failures };
};

async function createSchedule({
	campaignId,
	topics,
	startDate,
	endDate,
	rateMinutes,
}: CampaignEvent): Promise<void> {
	const rate = Math.max(5, Math.min(60, rateMinutes ?? 5));
	const schedulerInput = JSON.stringify({ id: campaignId, topics });

	await scheduler.send(
		new CreateScheduleCommand({
			ActionAfterCompletion: "DELETE",
			EndDate: new Date(endDate),
			FlexibleTimeWindow: { Mode: "OFF" },
			GroupName: SCHEDULE_GROUP_NAME,
			Name: campaignId,
			ScheduleExpression: `rate(${rate} minutes)`,
			StartDate: new Date(Math.max(Date.now(), new Date(startDate).getTime())),
			Target: {
				Arn: SCHEDULER_LAMBDA_ARN,
				Input: schedulerInput,
				RoleArn: SCHEDULER_ROLE_ARN,
			},
		}),
	);

	console.log(`Schedule created for campaign ${campaignId}`);
}

async function enqueueInitialFetch(
	id: string,
	topics: string[],
): Promise<void> {
	await sqs.send({
		MessageBody: JSON.stringify({
			id,
			topics,
		}),
		MessageDeduplicationId: `${id}-initial-${Date.now()}`,
		MessageGroupId: id,
		QueueUrl: CAMPAIGN_TOPICS_QUEUE_URL,
	});
}

async function deleteSchedule(campaignId: string): Promise<void> {
	try {
		await scheduler.send(
			new DeleteScheduleCommand({
				GroupName: SCHEDULE_GROUP_NAME,
				Name: campaignId,
			}),
		);
		console.log(`Campaign ${campaignId} schedule deleted`);
	} catch (err) {
		if (err instanceof Error && err.name === "ResourceNotFoundException") {
			console.log(`Schedule for ${campaignId} already deleted`);
		} else {
			throw err;
		}
	}
}
