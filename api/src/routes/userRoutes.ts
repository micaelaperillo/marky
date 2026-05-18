import { Router } from "express";
import { authMiddleware } from "@/middlewares/auth.js";
import { createCampaignHandler } from "@/controllers/campaignController.js";

export const userRouter = Router();

userRouter.get("/me", authMiddleware, (req, res) => {
  res.json({
    user: res.locals.user,
  });
});