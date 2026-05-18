import express from "express";
import { authMiddleware } from "./middlewares/auth.js";

export const app = express();

app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.get("/hello", (_req, res) => {
  res.json({ message: "Hello from Express Lambda" });
});

app.get("/me", authMiddleware, (_req, res) => {
  res.json({
    user: res.locals.user,
  });
});