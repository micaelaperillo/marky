import type { SQSHandler } from "aws-lambda";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

import { searchBlueSky } from "./bluesky";

const sns = new SNSClient({ region: process.env.AWS_REGION });

export const handler: SQSHandler = async (event) => {
    const failures: { itemIdentifier: string }[] = [];

    for (const record of event.Records) {
        try {
            const campaign = JSON.parse(record.body) as {
                id: string;
                topics: string[];
            };

            const results = await searchBlueSky(campaign);

            for (const result of results) {
                await sns.send(
                    new PublishCommand({
                        TopicArn: process.env.SNS_TOPIC_ARN,
                        Message: JSON.stringify(result),
                    }),
                );
            }
        } catch (err) {
            console.error("Failed record", record.messageId, err);
            failures.push({ itemIdentifier: record.messageId });
        }
    }

    return { batchItemFailures: failures };
};
