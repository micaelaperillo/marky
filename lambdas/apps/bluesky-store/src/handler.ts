import { S3EnvSchema } from "@shared/config";
import * as s3 from "@shared/service/s3";
import type { SNSMessage, SQSBatchItemFailure, SQSHandler } from "aws-lambda";

const env = S3EnvSchema.parse(process.env);

export const handler: SQSHandler = async (event) => {
	const failures: SQSBatchItemFailure[] = [];

	for (const record of event.Records) {
		try {
			const envelope = JSON.parse(record.body) as SNSMessage;
			const result = JSON.parse(envelope.Message);
			const unix = +new Date(result.fetchedAt);
			const key = `bluesky/${result.id}/${unix}.json`;

			await s3.store({
				Body: envelope.Message,
				Bucket: env.s3.bucket,
				ContentType: "application/json",
				Key: key,
			});

			console.log(`Stored data key=${key}`);
		} catch (err) {
			console.error("Failed record", record.messageId, err);
			failures.push({ itemIdentifier: record.messageId });
		}
	}

	return { batchItemFailures: failures };
};
