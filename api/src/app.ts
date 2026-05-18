import express from "express";

export const app = express();

app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.get("/hello", (_req, res) => {
  res.json({ message: "Hello from Express Lambda" });
});