import type { SQSHandler, SNSMessage, SQSBatchItemFailure } from "aws-lambda";

import { analyze } from "./analyze.js";
import { getGeminiApiKey } from "./secrets.js";
import { publishReport } from "./sqs.js";
import type { InputMessage } from "./types.js";

const apiKey = await getGeminiApiKey();

export const handler: SQSHandler = async (event) => {
    const failures: SQSBatchItemFailure[] = [];

    for (const record of event.Records) {
        try {
            const envelope = JSON.parse(record.body) as SNSMessage;
            const input = JSON.parse(envelope.Message) as InputMessage;

            console.log(
                `Processing report_id=${input.id} topics="${input.topics}" posts=${input.posts.length}`
            );

            const report = await analyze(apiKey, input);
            await publishReport(report);

            console.log(
                `Published report_id=${report.id} sentiment=${report.sentiment.label} (${report.sentiment.score})`
            );
        } catch (err) {
            console.error(`Failed record ${record.messageId}:`, err);
            failures.push({ itemIdentifier: record.messageId });
        }
    }

    return { batchItemFailures: failures };
};
