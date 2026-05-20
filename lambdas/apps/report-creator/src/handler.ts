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
            { cause: err }
        );
    }

    const m = body as Partial<InputMessage>;
    if (!m.id || !m.topics || !Array.isArray(m.posts)) {
        throw new Error(
            `SQS record ${record.messageId} missing required fields (report_id, topics, posts)`
        );
    }

    return m as InputMessage;
}

export const handler: SQSHandler = async (event) => {
    console.log(`Received ${event.Records.length} SQS record(s)`);

    const apiKey = await getGeminiApiKey();

    for (const record of event.Records) {
        const input = parseRecord(record);
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
