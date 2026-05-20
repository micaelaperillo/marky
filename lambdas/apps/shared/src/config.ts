import z from "zod";

const EnvSchema = z
    .object({
        AWS_REGION: z.string().default("us-east-1"),
        BACKEND_URL: z.url().default("http://127.0.0.1:8000"),
        S3_BUCKET_NAME: z.url(),
        COGNITO_CLIENT_ID: z.string().min(1),
        COGNITO_USER_POOL_ID: z.string().min(1),
        DYNAMODB_TABLE: z.string().default("reports"),
        DYNAMODB_ENDPOINT: z.url().optional(),
        DB_HOST: z.url(),
        DB_PORT: z.coerce.number().positive().default(5432),
        DB_NAME: z.string().min(1),
        DB_USER: z.string().min(1),
        DB_PASS: z.string().min(1),
        SQS_CAMPAIGNS_EVENTS_URL: z.url(),
        SQS_OUTPUT_REPORTS_URL: z.url(),
        LAMBDA_TASK_ROOT: z.string().optional(),
        NODE_ENV: z.enum(["development", "production"]).default("development")
    })
    .transform((env) => ({
        aws: {
            dynamoTable: env.DYNAMODB_TABLE,
            dynamoEndpoint: env.DYNAMODB_ENDPOINT,
            region: env.AWS_REGION
        },
        backendUrl: env.BACKEND_URL,
        s3: {
            bucket: env.S3_BUCKET_NAME
        },
        cognito: {
            clientId: env.COGNITO_CLIENT_ID,
            userPoolId: env.COGNITO_USER_POOL_ID
        },
        rds: {
            host: env.DB_HOST,
            port: env.DB_PORT,
            name: env.DB_NAME,
            user: env.DB_USER,
            pass: env.DB_PASS
        },
        sqs: {
            campaigns: env.SQS_CAMPAIGNS_EVENTS_URL,
            reports: env.SQS_OUTPUT_REPORTS_URL
        },
        isProduction: env.NODE_ENV === "production"
    }));

export const env = EnvSchema.parse(process.env);
