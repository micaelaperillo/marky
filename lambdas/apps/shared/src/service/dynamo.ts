import { DynamoDBClient } from "@aws-sdk/client-dynamodb";

import { env } from "@shared/config";

export const dynamo = new DynamoDBClient({ region: env.aws.region });
export const TABLE = env.aws.dynamoTable;
