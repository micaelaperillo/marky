import type { Campaign, CampaignInput } from "./types";

import { pool } from "@shared/service/postgres";

type CampaignRow = {
    id: string;
    user_sub: string;
    name: string;
    start_date: Date;
    end_date: Date;
    topics: string[];
};

export class RdsCampaignRepository {
    async findAll(userId: string): Promise<Campaign[]> {
        const result = await pool.query<CampaignRow>(
            `
                SELECT id, user_sub, name, start_date, end_date, topics
                FROM campaigns
                WHERE user_sub = $1
                ORDER BY start_date DESC
            `,
            [userId]
        );

        return result.rows.map(this.toDomain);
    }

    async findOne(userId: string, name: string): Promise<Campaign | null> {
        const result = await pool.query<CampaignRow>(
            `
                SELECT id, user_sub, name, start_date, end_date, topics
                FROM campaigns
                WHERE user_sub = $1 AND name = $2
                LIMIT 1
            `,
            [userId, name]
        );

        if (result.rowCount === 0) return null;

        return this.toDomain(result.rows[0]);
    }

    async save(input: CampaignInput & { userId: string }): Promise<string> {
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
            [input.userId, input.campaign, input.topics, input.start, input.end]
        );

        if (result.rowCount === 0)
            throw new Error("Unexpected lack of campaign id");

        return result.rows[0];
    }

    private toDomain(row: CampaignRow): Campaign {
        return {
            id: row.id,
            userId: row.user_sub,
            name: row.name,
            topics: row.topics,
            start: row.start_date.toISOString(),
            end: row.end_date.toISOString()
        };
    }
}
