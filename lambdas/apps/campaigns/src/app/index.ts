import express from "express";

import { errorMiddleware } from "@shared/express/errors";
import { authenticated } from "@shared/service/cognito";
import * as validate from "@shared/express/validate";

import { RdsCampaignRepository } from "./repository";
import { CampaignInputSchema, CampaignParamsSchema } from "./validations";

const repo = new RdsCampaignRepository();

const app = express();

app.use(express.json());
app.use(authenticated);

app.route("/")
    .get(async (_req, res, next) => {
        try {
            const campaigns = await repo.findAll(res.locals.userId);
            res.json(campaigns);
        } catch (err) {
            next(err);
        }
    })
    .post(validate.body(CampaignInputSchema), async (req, res, next) => {
        try {
            const id = await repo.save({
                ...req.body,
                userId: res.locals.userId
            });

            res.status(201).json({ id });
        } catch (err) {
            next(err);
        }
    });

app.route("/:name")
  .get(
    validate.params(CampaignParamsSchema),
    async (req, res, next) => {
      try {
        const campaign = await repo.findOne(
          res.locals.userId,
          req.params.name
        );

        if (!campaign) {
          return res.status(404).json({ message: "Campaign not found" });
        }

        res.json(campaign);
      } catch (err) {
        next(err);
      }
    });

app.use(errorMiddleware);

export default app;
