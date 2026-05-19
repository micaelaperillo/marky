import express from "express";

import { errorMiddleware } from "@shared/express/errors";
import { authenticated } from "@shared/service/cognito";
import * as validate from "@shared/express/validate";

import { RdsCampaignRepository } from "./repository";
import { CampaignInputSchema } from "./validations";

const repo = new RdsCampaignRepository();

const app = express();

app.use(express.json());
app.use(errorMiddleware);
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

export default app;
