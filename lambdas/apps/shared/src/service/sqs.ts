import {
    SendMessageCommand,
    SendMessageCommandInput,
    SQSClient
} from "@aws-sdk/client-sqs";

const sqs = new SQSClient();

export async function send(message: SendMessageCommandInput) {
    return sqs.send(new SendMessageCommand(message));
}
