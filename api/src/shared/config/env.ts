import z from "zod";

const EnvSchema = z
	.object({
		AWS_REGION: z.string().default("us-east-1"),
		BACKEND_URL: z.string().url().default("http://127.0.0.1:8000"),
		COOKIE_SECRET: z.string().min(1),
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
		dev: {
			port: env.PORT,
		},
		express: {
			cookieSecret: env.COOKIE_SECRET,
		},
		isProduction: env.NODE_ENV === "production",
	}));

export const env = EnvSchema.parse(process.env);
