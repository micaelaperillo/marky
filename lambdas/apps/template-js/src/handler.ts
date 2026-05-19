import type { APIGatewayProxyHandlerV2 } from "aws-lambda";

import { hello_world } from "shared/src/my-library";

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
    if (event.requestContext.http.method.toUpperCase() === "GET") {
        return {
            statusCode: 200,
            body: `<h1>${hello_world()}</h1>`
        };
    }

    return {
        statusCode: 200,
        body: JSON.stringify({ test: "Hello from Lambda!" })
    };
};
