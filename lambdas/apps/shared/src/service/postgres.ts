import { Pool } from "pg";

import { env } from "@shared/config";

export const pool = new Pool({
    host: env.rds.host,
    port: env.rds.port,
    database: env.rds.name,
    user: env.rds.user,
    password: env.rds.pass,
    max: 1
});
