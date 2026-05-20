import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { Pool } from "pg";

const SQL = `
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_sub TEXT NOT NULL,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  topics TEXT[] NOT NULL,
  CONSTRAINT campaigns_user_name_unique UNIQUE (user_sub, name)
);
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
