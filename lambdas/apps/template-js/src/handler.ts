import type { APIGatewayProxyHandlerV2 } from "aws-lambda";

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
    if (event.requestContext.http.method.toUpperCase() === "GET") {
        return {
            statusCode: 200,
            body: "<h1>Hi</h1>"
        };
    }

    return {
        statusCode: 200,
        body: JSON.stringify({ test: "Hello from Lambda!" })
    };
};
