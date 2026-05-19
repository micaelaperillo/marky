import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

import type { OutputReport } from "./types.js";

const region = process.env.AWS_REGION ?? "us-east-1";
const client = new SQSClient({ region });

export async function publishReport(report: OutputReport): Promise<void> {
    const queueUrl = process.env.OUTPUT_SQS_QUEUE_URL;
    if (!queueUrl) {
        throw new Error("OUTPUT_SQS_QUEUE_URL env var is required");
    }

    await client.send(
        new SendMessageCommand({
            QueueUrl: queueUrl,
            MessageBody: JSON.stringify(report),
            MessageAttributes: {
                report_id: {
                    DataType: "String",
                    StringValue: report.report_id
                },
                query: {
                    DataType: "String",
                    StringValue: report.query
                }
            }
        })
    );
}
