import { getPool, type PoolClient } from "@shared/service/postgres";
import type { Campaign, CampaignInput } from "./types";

type CampaignRow = {
	id: string;
	user_sub: string;
	name: string;
	start_date: Date;
	end_date: Date;
	frequency_min: number;
	topics: string[];
};

type SaveInput = CampaignInput & {
	userId: string;
	name: string;
};

export class RdsCampaignRepository {
	async findAll(userId: string, status: string = "all"): Promise<Campaign[]> {
		const pool = await getPool();
		const result = await pool.query<CampaignRow>(
			`
                SELECT id, user_sub, name, start_date, end_date, frequency_min, topics
                FROM campaigns
                WHERE user_sub = $1
                AND (
                    ($2 = 'all') OR
                    ($2 = 'active' AND CURRENT_TIMESTAMP >= start_date AND CURRENT_TIMESTAMP <= end_date) OR
                    ($2 = 'pending' AND start_date > CURRENT_TIMESTAMP) OR
                    ($2 = 'ended' AND end_date < CURRENT_TIMESTAMP)
                )
                ORDER BY start_date DESC
            `,
			[userId, status],
		);

		return result.rows.map(this.toDomain);
	}

	async getStats(userId: string): Promise<{ total: number; active: number; topics: number }> {
		const pool = await getPool();
		const result = await pool.query(
			`
                SELECT 
                    COUNT(*)::int as total,
                    COUNT(*) FILTER (WHERE CURRENT_TIMESTAMP >= start_date AND CURRENT_TIMESTAMP <= end_date)::int as active,
                    COALESCE(SUM(cardinality(topics)), 0)::int as topics
                FROM campaigns
                WHERE user_sub = $1
            `,
			[userId],
		);

		return result.rows[0];
	}

	async findById(userId: string, id: string): Promise<Campaign | null> {
		const pool = await getPool();
		const result = await pool.query<CampaignRow>(
			`
                SELECT id, user_sub, name, start_date, end_date, frequency_min, topics
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
                    end_date,
                    frequency_min
                )
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING id
            `,
			[input.userId, input.name, input.topics, input.start, input.end, input.frequencyMin],
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
                    end_date,
                    frequency_min
                )
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING id
            `,
			[input.userId, input.name, input.topics, input.start, input.end, input.frequencyMin],
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
			frequencyMin: row.frequency_min
		};
	}
}
