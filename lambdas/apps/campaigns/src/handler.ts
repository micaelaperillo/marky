import type { APIGatewayProxyHandlerV2 } from "aws-lambda";

import serverless from "serverless-http";

import app from "./app";
import pkg from "../package.json" with { type: "json" };

const serverlessHandler = serverless(app, {
    binary: false,
    basePath: `/prod/${pkg.name}`
});

export const handler: APIGatewayProxyHandlerV2 = async (event, context) => {
    return serverlessHandler(event, context);
};
