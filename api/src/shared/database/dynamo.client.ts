import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { env } from "../config/env.js";

export const dynamoClient = new DynamoDBClient({ region: env.aws.region });
export const TABLE = env.aws.dynamoTable;
