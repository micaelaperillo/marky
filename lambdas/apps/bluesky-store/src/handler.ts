import type { SQSHandler } from "aws-lambda";

import { storeResult } from "./s3.js";
import type { BlueSkyResult } from "./types.js";

export const handler: SQSHandler = async (event) => {
    const failures: { itemIdentifier: string }[] = [];

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
