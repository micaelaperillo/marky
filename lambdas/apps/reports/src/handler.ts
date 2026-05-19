import type { APIGatewayProxyHandlerV2 } from "aws-lambda";

import serverless from "serverless-http";

import app from "./app";

const serverlessHandler = serverless(app, {
    binary: false
});

export const handler: APIGatewayProxyHandlerV2 = async (event, context) => {
    return serverlessHandler(event, context);
};
