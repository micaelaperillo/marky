import {
    DynamoDBClient,
    PutItemCommand,
    type PutItemCommandInput
} from "@aws-sdk/client-dynamodb";

import { env } from "@shared/config";

export const dynamo = new DynamoDBClient({
    region: env.aws.region,
    endpoint: env.aws.dynamoEndpoint,
    ...(!env.isProduction && {
        credentials: {
            accessKeyId: "local",
            secretAccessKey: "local"
        }
    })
});

export function put(input: PutItemCommandInput) {
    return dynamo.send(new PutItemCommand(input));
}

export const TABLE = env.aws.dynamoTable;
