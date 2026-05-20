import type { BlueSkyResult } from "./types.js";

import { env } from "@shared/config";

import * as s3 from "@shared/service/s3";

export async function storeResult(result: BlueSkyResult) {
    const unix = +new Date(result.fetchedAt);
    const key = `bluesky/${result.id}/${unix}.json`;

    await s3.store({
        Bucket: env.s3.bucket,
        Key: key,
        Body: JSON.stringify(result),
        ContentType: "application/json"
    });
}
