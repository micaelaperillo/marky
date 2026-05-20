import {
	DynamoDBClient,
	PutItemCommand,
	type PutItemCommandInput,
} from "@aws-sdk/client-dynamodb";

import { DynamoEnvSchema } from "@shared/config";

const env = DynamoEnvSchema.parse(process.env);

export const dynamo = new DynamoDBClient({
	endpoint: env.aws.dynamoEndpoint,
	region: env.aws.region,
	...(!env.isProduction && {
		credentials: {
			accessKeyId: "local",
			secretAccessKey: "local",
		},
	}),
});

export function put(input: PutItemCommandInput) {
	return dynamo.send(new PutItemCommand(input));
}

export const TABLE = env.aws.dynamoTable;
