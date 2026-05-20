import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { SecretsEnvSchema } from "@shared/config";
import z from "zod";

const env = SecretsEnvSchema.parse(process.env);

export async function getGeminiApiKey() {
	return z.string().parse(await getSecret(env.sm.gemini));
}
