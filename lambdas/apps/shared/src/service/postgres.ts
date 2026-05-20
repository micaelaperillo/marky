import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { Pool } from "pg";
import z from "zod";

import { env } from "@shared/config";

const data = z
    .object({
        username: z.string().min(1),
        password: z.string(),
        dbname: z.string().min(1),
        port: z.number(),
        host: z.string()
    })
    .transform((e) => ({
        host: e.host,
        port: e.port,
        database: e.dbname,
        user: e.username,
        password: e.password
    }))
    .parse(await getSecret(env.sm.rds));

export const pool = new Pool({
    ...data,
    max: 1
});
