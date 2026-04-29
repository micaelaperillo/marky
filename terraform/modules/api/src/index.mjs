export const handler = async (event) => {
  const path = event.path || "/";
  const method = event.httpMethod || "GET";

  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Marky API",
      method,
      path,
    }),
  };
};
