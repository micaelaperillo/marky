import z from "zod";

export const BaseEnvSchema = z.object({
	AWS_REGION: z.string().default("us-east-1"),
	LAMBDA_TASK_ROOT: z.string().optional(),
	NODE_ENV: z.enum(["development", "production"]).default("development"),
});

export const CognitoEnvSchema = BaseEnvSchema.extend({
	COGNITO_CLIENT_ID: z.string().min(1),
	COGNITO_USER_POOL_ID: z.string().min(1),
}).transform((e) => ({
	cognito: {
		clientId: e.COGNITO_CLIENT_ID,
		userPoolId: e.COGNITO_USER_POOL_ID,
	},
}));

export const DynamoEnvSchema = BaseEnvSchema.extend({
	DYNAMODB_ENDPOINT: z.url().optional(),
	DYNAMODB_TABLE: z.string().default("reports"),
}).transform((e) => ({
	aws: {
		dynamoEndpoint: e.DYNAMODB_ENDPOINT,
		dynamoTable: e.DYNAMODB_TABLE,
		region: e.AWS_REGION,
	},
	isProduction: e.NODE_ENV === "production",
}));

export const S3EnvSchema = BaseEnvSchema.extend({
	S3_BUCKET_NAME: z.string().min(1),
}).transform((e) => ({
	s3: { bucket: e.S3_BUCKET_NAME },
}));

export const PostgresEnvSchema = BaseEnvSchema.extend({
	SM_RDS_CREDENTIALS_ID: z.string().min(1),
}).transform((e) => ({
	sm: { rds: e.SM_RDS_CREDENTIALS_ID },
}));

export const SecretsEnvSchema = BaseEnvSchema.extend({
	SM_GEMINI_API_KEY_SECRET_ID: z.string().min(1),
}).transform((e) => ({
	sm: { gemini: e.SM_GEMINI_API_KEY_SECRET_ID },
}));

export const SqsCampaignsEnvSchema = BaseEnvSchema.extend({
	SQS_CAMPAIGNS_EVENTS_URL: z.url(),
}).transform((e) => ({
	sqs: { campaigns: e.SQS_CAMPAIGNS_EVENTS_URL },
}));

export const SqsReportsEnvSchema = BaseEnvSchema.extend({
	SQS_OUTPUT_REPORTS_URL: z.url(),
}).transform((e) => ({
	sqs: { reports: e.SQS_OUTPUT_REPORTS_URL },
}));
