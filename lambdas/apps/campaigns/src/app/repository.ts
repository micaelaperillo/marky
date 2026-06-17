import { getPool, type PoolClient } from "@shared/service/postgres";
import type { Campaign, CampaignInput } from "./types";

type CampaignRow = {
	id: string;
	user_sub: string;
	name: string;
	start_date: Date;
	end_date: Date;
	topics: string[];
};

type SaveInput = CampaignInput & {
	userId: string;
	name: string;
};

export class RdsCampaignRepository {
	async findAll(userId: string): Promise<Campaign[]> {
		const pool = await getPool();
		const result = await pool.query<CampaignRow>(
			`
                SELECT id, user_sub, name, start_date, end_date, topics
                FROM campaigns
                WHERE user_sub = $1
                ORDER BY start_date DESC
            `,
			[userId],
		);

		return result.rows.map(this.toDomain);
	}

	async findById(userId: string, id: string): Promise<Campaign | null> {
		const pool = await getPool();
		const result = await pool.query<CampaignRow>(
			`
                SELECT id, user_sub, name, start_date, end_date, topics
                FROM campaigns
                WHERE user_sub = $1 AND id = $2
                LIMIT 1
            `,
			[userId, id],
		);

		if (result.rowCount === 0) return null;

		return this.toDomain(result.rows[0]);
	}

	async save(input: SaveInput): Promise<string> {
		const pool = await getPool();
		const result = await pool.query(
			`
                INSERT INTO campaigns (
                    user_sub,
                    name,
                    topics,
                    start_date,
                    end_date
                )
                VALUES ($1, $2, $3, $4, $5)
                RETURNING id
            `,
			[input.userId, input.name, input.topics, input.start, input.end],
		);

		if (result.rowCount === 0)
			throw new Error("Unexpected lack of campaign id");

		return result.rows[0].id;
	}

	async saveWithClient(client: PoolClient, input: SaveInput): Promise<string> {
		const result = await client.query(
			`
                INSERT INTO campaigns (
                    user_sub,
                    name,
                    topics,
                    start_date,
                    end_date
                )
                VALUES ($1, $2, $3, $4, $5)
                RETURNING id
            `,
			[input.userId, input.name, input.topics, input.start, input.end],
		);

		if (result.rowCount === 0)
			throw new Error("Unexpected lack of campaign id");

		return result.rows[0].id;
	}

	async delete(userId: string, id: string): Promise<boolean> {
		const pool = await getPool();
		const result = await pool.query(
			"DELETE FROM campaigns WHERE user_sub = $1 AND id = $2",
			[userId, id],
		);
		return (result.rowCount ?? 0) > 0;
	}

	private toDomain(row: CampaignRow): Campaign {
		return {
			end: row.end_date.toISOString(),
			id: row.id,
			name: row.name,
			start: row.start_date.toISOString(),
			topics: row.topics,
			userId: row.user_sub,
		};
	}
}
