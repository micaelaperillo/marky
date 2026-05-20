import express from "express";
import cors from "cors";

import reportsApp from "reports/src/app";
import campaignsApp from "campaigns/src/app";
import usersApp from "users/src/app";

const app = express();

app.use(
    cors({
        origin: "http://localhost:5173",
        methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allowedHeaders: ["Content-Type", "Authorization"]
    })
);

app.use("/reports", reportsApp);
app.use("/campaigns", campaignsApp);
app.use("/auth", usersApp);

app.listen(3000, () => {
    console.log("Local API Gateway running on http://localhost:3000");
});
