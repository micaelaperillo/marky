import type { SQSHandler, SNSMessage } from "aws-lambda";

import { analyze } from "./analyze.js";
import { getGeminiApiKey } from "./secrets.js";
import { publishReport } from "./sqs.js";
import type { InputMessage } from "./types.js";

export const handler: SQSHandler = async (event) => {
    console.log(`Received ${event.Records.length} SQS record(s)`);

    const apiKey = await getGeminiApiKey();

    for (const record of event.Records) {
        const envelope = JSON.parse(record.body) as SNSMessage;
        const input = JSON.parse(envelope.Message) as InputMessage;

        console.log(
            `Processing report_id=${input.id} topics="${input.topics}" posts=${input.posts.length}`
        );

        const report = await analyze(apiKey, input);
        await publishReport(report);

        console.log(
            `Published report_id=${report.report_id} sentiment=${report.sentiment.label} (${report.sentiment.score})`
        );
    }
};
