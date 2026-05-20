import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { PostgresEnvSchema } from "@shared/config";
import { Pool, type PoolClient } from "pg";
export type { PoolClient };

import z from "zod";

const env = PostgresEnvSchema.parse(process.env);

const CredentialsSchema = z
	.object({
		dbname: z.string().min(1),
		host: z.string(),
		password: z.string(),
		port: z.number(),
		username: z.string().min(1),
	})
	.transform((e) => ({
		database: e.dbname,
		host: e.host,
		password: e.password,
		port: e.port,
		user: e.username,
	}));

let _pool: Pool | null = null;

export async function getPool(): Promise<Pool> {
	if (_pool) return _pool;
	const raw = await getSecret(env.sm.rds);
	const data = CredentialsSchema.parse(JSON.parse(raw as string));
	_pool = new Pool({ ...data, max: 1, ssl: true });
	return _pool;
}
