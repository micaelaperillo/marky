import type { SQSHandler, SQSBatchItemFailure } from "aws-lambda";

import { env } from "@shared/config";
import * as s3 from "@shared/service/s3";

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
    const failures: SQSBatchItemFailure[] = [];

    for (const record of event.Records) {
        try {
            const envelope = JSON.parse(record.body) as { Message: string };
            const result = JSON.parse(envelope.Message) as BlueSkyResult;

            await storeResult(result);

            console.log(
                `Stored campaignId=${result.id} topic="${result.topics.join(",")}" posts=${result.posts.length}`
            );
        } catch (err) {
            console.error("Failed record", record.messageId, err);
            failures.push({ itemIdentifier: record.messageId });
        }
    }

    return { batchItemFailures: failures };
};

export async function storeResult(result: BlueSkyResult) {
    const unix = +new Date(result.fetchedAt);
    const key = `bluesky/${result.id}/${unix}.json`;

    await s3.store({
        Bucket: env.s3.bucket,
        Key: key,
        Body: JSON.stringify(result),
        ContentType: "application/json"
    });
}
