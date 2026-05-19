import express from "express";

import { authenticated } from "@shared/service/cognito";
import { pool } from "@shared/service/postgres";

const app = express();

app.use(express.json());

app.route("/me")
    // Only return user id if logged in
    .get(authenticated, async (_req, res) => {
        res.json({
            id: res.locals.userId,
            email: res.locals.email,
        });
    });

export default app;
