import express from "express";

import { authenticated } from "@shared/service/cognito";
import { pool } from "@shared/service/postgres";

const app = express();

app.use(express.json());

app.route("/me")
    // Only return user id if logged in
    .get(authenticated, async (_req, res) => {
        const id = res.locals.userId;
        const results = await pool.query("SELECT * FROM users WHERE id = $1", [
            id
        ]);

        const user = results.rows[0];

        if (!user) {
            return res.sendStatus(404);
        }

        res.send(user);
    });

export default app;
