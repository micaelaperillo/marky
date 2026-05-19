import { SentimentPoint, Report } from "../report.types";

export interface IReportRepository {
  findOne(campaignId: string, timestamp: string): Promise<Report | null>;

  findLatestByCampaignId(campaignId: string): Promise<Report | null>;

  findReportsByCampaignIdBetween(
    campaignId: string,
    start: string,
    end: string
  ): Promise<Report[]>;

  findSentimentPointsByCampaignIdBetween(
    campaignId: string,
    start: string,
    end: string
  ): Promise<SentimentPoint[]>;
}