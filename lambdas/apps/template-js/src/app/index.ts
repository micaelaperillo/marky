import express from "express";

import { errorMiddleware } from "@shared/express/errors";

const app = express();

app.use(express.json());
app.use(errorMiddleware);

app.route("/")
    .get((req, res) => {
        res.send("hello_world()");
    })
    .post((req, res) => {
        res.sendStatus(201);
    });

export default app;
