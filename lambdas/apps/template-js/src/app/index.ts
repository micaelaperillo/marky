import express from "express";

import { hello_world } from "shared/src/my-library";

const app = express();

app.route("/")
    .get((req, res) => {
        res.send(hello_world());
    })
    .post((req, res) => {
        res.sendStatus(201);
    });

export default app;
