import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

import type { BlueSkyResult } from "./types.js";

const s3 = new S3Client({ region: process.env.AWS_REGION });
const BUCKET = process.env.S3_BUCKET_NAME!;

export async function storeResult(result: BlueSkyResult): Promise<void> {
    const topicSlug = result.topic
        .toLowerCase()
        .replace(/\s+/g, "-")
        .replace(/[^a-z0-9-]/g, "");
    const timestamp = result.fetchedAt.replace(/:/g, "-");
    const key = `bluesky/${result.campaignId}/${topicSlug}/${timestamp}.json`;

    await s3.send(
        new PutObjectCommand({
            Bucket: BUCKET,
            Key: key,
            Body: JSON.stringify(result),
            ContentType: "application/json",
        }),
    );
}