import type { SQSHandler } from "aws-lambda";

import { storeResult } from "./s3.js";
import type { BlueSkyResult } from "./types.js";

export const handler: SQSHandler = async (event) => {
    const failures: { itemIdentifier: string }[] = [];

    for (const record of event.Records) {
        try {
            const snsEnvelope = JSON.parse(record.body) as { Message: string };
            const result = JSON.parse(snsEnvelope.Message) as BlueSkyResult;
            await storeResult(result);
            console.log(
                `Stored campaignId=${result.campaignId} topic="${result.topic}" posts=${result.posts.length}`,
            );
        } catch (err) {
            console.error("Failed record", record.messageId, err);
            failures.push({ itemIdentifier: record.messageId });
        }
    }

    return { batchItemFailures: failures };
};