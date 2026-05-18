import { Router } from "express";
import { authMiddleware } from "@/middlewares/auth.js";
import { createCampaignHandler } from "@/controllers/campaignController.js";

export const campaignsRouter = Router();

campaignsRouter.post("/", authMiddleware, createCampaignHandler);