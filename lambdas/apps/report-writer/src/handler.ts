import type { SQSBatchResponse, SQSHandler } from "aws-lambda";
import { marshall } from "@aws-sdk/util-dynamodb";

import { env } from "@shared/config";

import * as dynamo from "@shared/service/dynamo";

export const handler: SQSHandler = async (event) => {
    const failures: SQSBatchResponse["batchItemFailures"] = [];

    for (const record of event.Records) {
        try {
            dynamo.put({
                TableName: env.aws.dynamoTable,
                Item: mapper(JSON.parse(record.body))
            });
        } catch (err) {
            console.error(`Failed to store record ${record.messageId}:`, err);
            failures.push({ itemIdentifier: record.messageId });
        }
    }

    return { batchItemFailures: failures };
};

function mapper(data: {
    id: string;
    fetchedAt: string;
    sentiment: {
        score: number;
    };
    [k: string]: unknown;
}) {
    const row: Record<string, unknown> = {
        PK: `CAMPAIGN#${data.id}`,
        SK: `REPORT#${data.fetchedAt}`,

        campaign_id: data.id,
        timestamp: data.fetchedAt,
        sentiment: data.sentiment.score,

        report: data
    };

    return marshall(row);
}
