import type { OutputReport } from "./types.js";

import { env } from "@shared/config";

import * as sqs from "@shared/service/sqs";

export async function publishReport(report: OutputReport) {
    sqs.send({
        QueueUrl: env.sqs.reports,
        MessageBody: JSON.stringify(report)
    });
}
