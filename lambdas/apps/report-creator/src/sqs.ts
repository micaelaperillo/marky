import { SqsReportsEnvSchema } from "@shared/config";
import * as sqs from "@shared/service/sqs";
import type { OutputReport } from "./types.js";

const env = SqsReportsEnvSchema.parse(process.env);

export async function publishReport(report: OutputReport) {
    await sqs.send({
        MessageBody: JSON.stringify(report),
        MessageGroupId: report.id,
        QueueUrl: env.sqs.reports,
        MessageAttributes: {
            key: {
                DataType: "String",
                StringValue: `bluesky/${report.id}/${+new Date(report.fetchedAt)}.json`
            }
        }
    });
}
