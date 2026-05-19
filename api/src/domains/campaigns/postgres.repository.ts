// src/campaigns/repositories/rds-campaign.repository.ts
import { postgresPool as postgresClient} from "@shared/database/postgresproxy.client.js";
import type { Campaign } from "./campaign.types.js";
import type { ICampaignRepository, SaveCampaignInput } from "./interfaces/campaign.repository.js";


type CampaignRow = {
  id: string;
  user_sub: string;
  name: string;
  start_date: Date;
  end_date: Date;
  topics: string[];
};

export class RdsCampaignRepository implements ICampaignRepository {
  async findAll(userId: string): Promise<Campaign[]> {
    const result = await postgresClient.query<CampaignRow>(
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
    const result = await postgresClient.query<CampaignRow>(
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

  async save(input: SaveCampaignInput): Promise<void> {
    await postgresClient.query(
      `
      INSERT INTO campaigns (
        user_sub,
        name,
        topics,
        start_date,
        end_date
      )
      VALUES ($1, $2, $3, $4, $5)
      `,
      [
        input.userId,
        input.name,
        input.topics,
        input.start,
        input.end,
      ]
    );
  }

  private toDomain(row: CampaignRow): Campaign {
    return {
      id: row.id,
      userId: row.user_sub,
      name: row.name,
      topics: row.topics,
      start: row.start_date.toISOString(),
      end: row.end_date.toISOString(),
    };
  }
}