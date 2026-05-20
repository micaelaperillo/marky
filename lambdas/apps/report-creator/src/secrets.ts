import {
    SecretsManagerClient,
    GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager";

const region = process.env.AWS_REGION ?? "us-east-1";
const client = new SecretsManagerClient({ region });

let cachedApiKey: string | null = null;

export async function getGeminiApiKey(): Promise<string> {
    if (cachedApiKey) {
        return cachedApiKey;
    }

    const secretName =
        process.env.GEMINI_API_KEY_SECRET_NAME ?? "gemini-api-key";

    const resp = await client.send(
        new GetSecretValueCommand({ SecretId: secretName })
    );

    if (!resp.SecretString) {
        throw new Error(`Secret ${secretName} has no SecretString`);
    }

    const parsed = JSON.parse(resp.SecretString) as {
        GEMINI_API_KEY?: string;
    };

    if (!parsed.GEMINI_API_KEY) {
        throw new Error(`Secret ${secretName} missing GEMINI_API_KEY field`);
    }

    cachedApiKey = parsed.GEMINI_API_KEY;
    return cachedApiKey;
}
