import z from "zod";

const EnvSchema = z
	.object({
		AWS_REGION: z.string().default("us-east-1"),
		BACKEND_URL: z.string().url().default("http://127.0.0.1:8000"),
		COGNITO_CLIENT_ID: z.string().min(1),
		COGNITO_USER_POOL_ID: z.string().min(1),
		DYNAMODB_TABLE: z.string().default("marky-data"),
		LAMBDA_TASK_ROOT: z.string().optional(),
		NODE_ENV: z.enum(["development", "production"]).default("development"),
		PORT: z.coerce.number().int().default(3001),
	})
	.transform((env) => ({
		aws: {
			dynamoTable: env.DYNAMODB_TABLE,
			lambdaTask: env.LAMBDA_TASK_ROOT,
			region: env.AWS_REGION,
		},
		backendUrl: env.BACKEND_URL,
		cognito: {
			clientId: env.COGNITO_CLIENT_ID,
			userPoolId: env.COGNITO_USER_POOL_ID,
		},
		dev: {
			port: env.PORT,
		},
		isProduction: env.NODE_ENV === "production",
	}));

export const env = EnvSchema.parse(process.env);
