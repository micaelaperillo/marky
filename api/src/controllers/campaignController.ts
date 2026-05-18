import type { Request, Response } from "express";
import { createCampaign } from "@/repositories/campaignRepository.js";

export async function createCampaignHandler(req: Request, res: Response) {
  const { campaignName, startDate, endDate, topics } = req.body;

  if (!campaignName || !startDate || !endDate || !Array.isArray(topics)) {
    return res.status(400).json({ message: "Invalid campaign data" });
  }

  const userId = res.locals.user.sub;

  const campaign = await createCampaign({
    userId,
    campaignName,
    startDate,
    endDate,
    topics,
  });

  return res.status(201).json(campaign);
}