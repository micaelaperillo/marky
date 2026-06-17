import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { Pool } from "pg";

const SQL = `
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_sub TEXT NOT NULL,
  name TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  frequency_min INTEGER NOT NULL DEFAULT 60,
  topics TEXT[] NOT NULL,

  CONSTRAINT campaigns_user_name_unique UNIQUE (user_sub, name)
);

ALTER TABLE campaigns ALTER COLUMN start_date TYPE TIMESTAMPTZ USING start_date::TIMESTAMPTZ;
ALTER TABLE campaigns ALTER COLUMN end_date TYPE TIMESTAMPTZ USING end_date::TIMESTAMPTZ;
`;

export const handler = async () => {
	const secretId = process.env.SM_RDS_CREDENTIALS_ID;
	if (!secretId) {
		throw new Error("SM_RDS_CREDENTIALS_ID env var is not set");
	}

	const raw = await getSecret(secretId);
	if (typeof raw !== "string") {
		throw new Error("Secret value is not a string");
	}

	const creds = JSON.parse(raw) as {
		username: string;
		password: string;
		host: string;
		port: number;
		dbname: string;
	};

	const pool = new Pool({
		database: creds.dbname,
		host: creds.host,
		max: 1,
		password: creds.password,
		port: creds.port,
		ssl: true,
		user: creds.username,
	});

	try {
		await pool.query(SQL);
		return { message: "Migration complete", success: true };
	} finally {
		await pool.end();
	}
};
