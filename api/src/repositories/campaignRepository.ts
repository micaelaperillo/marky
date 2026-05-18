import { pool } from "@databases/rdsProxy";

export type CreateCampaignInput = {
  userId: string;
  campaignName: string;
  startDate: string;
  endDate: string;
  topics: string[];
};

export async function createCampaign(input: CreateCampaignInput) {
  const result = await pool.query(
    `
    INSERT INTO campaigns (
      user_id,
      campaign_name,
      start_date,
      end_date,
      topics
    )
    VALUES ($1, $2, $3, $4, $5)
    RETURNING
      campaign_id,
      user_id,
      campaign_name,
      start_date,
      end_date,
      topics
    `,
    [
      input.userId,
      input.campaignName,
      input.startDate,
      input.endDate,
      input.topics,
    ]
  );

  return result.rows[0];
}