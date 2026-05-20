import {
    S3Client,
    PutObjectCommand,
    type PutObjectCommandInput
} from "@aws-sdk/client-s3";

const s3 = new S3Client();

export async function store(input: PutObjectCommandInput) {
    await s3.send(new PutObjectCommand(input));
}
