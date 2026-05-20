import { S3EnvSchema } from "@shared/config";
import * as s3 from "@shared/service/s3";
import type { SQSHandler } from "aws-lambda";

const env = S3EnvSchema.parse(process.env);

export interface BlueSkyPost {
	uri: string;
	text: string;
	date: string;
	user: string;
	avatar?: string;
	likeCount: number;
	repostCount: number;
}

export interface BlueSkyResult {
	id: string;
	topics: string[];
	fetchedAt: string;
	posts: BlueSkyPost[];
}

export const handler: SQSHandler = async (event) => {
	const failures: { itemIdentifier: string }[] = [];

	for (const record of event.Records) {
		try {
			const raw = JSON.parse(record.body);
			if (!raw.id || !raw.fetchedAt || !Array.isArray(raw.posts)) {
				throw new Error("Invalid message: missing id, fetchedAt, or posts");
			}
			const result = raw as BlueSkyResult;

			await storeResult(result);

			console.log(
				`Stored campaignId=${result.id} topic="${result.topics.join(",")}" posts=${result.posts.length}`,
			);
		} catch (err) {
			console.error("Failed record", record.messageId, err);
			failures.push({ itemIdentifier: record.messageId });
		}
	}

	return { batchItemFailures: failures };
};

async function storeResult(result: BlueSkyResult) {
	const unix = +new Date(result.fetchedAt);
	const key = `bluesky/${result.id}/${unix}.json`;

	await s3.store({
		Body: JSON.stringify(result),
		Bucket: env.s3.bucket,
		ContentType: "application/json",
		Key: key,
	});
}
