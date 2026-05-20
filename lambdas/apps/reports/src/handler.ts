import type { APIGatewayProxyHandler } from "aws-lambda";

import serverless from "serverless-http";

import app from "./app";

const serverlessHandler = serverless(app, {
	basePath: `/api/reports`,
	binary: false,
});

export const handler: APIGatewayProxyHandler = async (event, context) => {
	return serverlessHandler(event, context);
};
