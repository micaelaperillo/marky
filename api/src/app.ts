import express from "express";
import { campaignsRouter } from "@/routes/campaignRoutes.js";
import { userRouter } from "@/routes/userRoutes.js";


export const app = express();

app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.use("/campaigns", campaignsRouter);
app.use("/users", userRouter);