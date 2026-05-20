import { DynamoDBClient } from "@aws-sdk/client-dynamodb";

import { env } from "@shared/config";

export const dynamo = new DynamoDBClient({
  region: env.aws.region,
  endpoint: env.aws.dynamoEndpoint,
  ...(env.nodeEnv === "development" && {
    credentials: {
      accessKeyId: "local",
      secretAccessKey: "local"
    }
  })
});

export const TABLE = env.aws.dynamoTable;
