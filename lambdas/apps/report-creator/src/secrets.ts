import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { z } from "zod/v4/mini";

import { env } from "@shared/config";

export async function getGeminiApiKey() {
    return z.string().parse(await getSecret(env.sm.gemini));
}
