import type { WriteRequest } from "@aws-sdk/client-dynamodb";
import { BatchWriteItemCommand } from "@aws-sdk/client-dynamodb";
import { dynamoClient, TABLE } from "@shared/database/dynamo.client.js";
import type { ITaskRepository } from "./interfaces/task.repository.js";
import type { TaskInput } from "./task.types.js";

const MAX_RETRIES = 3;

export class DynamoTaskRepository implements ITaskRepository {
	async batchCreate(tasks: TaskInput[]): Promise<void> {
		const chunks: TaskInput[][] = [];
		for (let i = 0; i < tasks.length; i += 25) {
			chunks.push(tasks.slice(i, i + 25));
		}

		for (const chunk of chunks) {
			let items: WriteRequest[] = chunk.map((t) => ({
				PutRequest: {
					Item: {
						PK: { S: `TASKS#${t.schedule}` },
						SK: { S: `${t.topic}#${t.date}` },
					},
				},
			}));

			for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
				const result = await dynamoClient.send(
					new BatchWriteItemCommand({ RequestItems: { [TABLE]: items } }),
				);

				const unprocessed = result.UnprocessedItems?.[TABLE];
				if (!unprocessed?.length) break;

				if (attempt === MAX_RETRIES) {
					throw new Error(
						`Failed to write ${unprocessed.length} items after ${MAX_RETRIES} retries`,
					);
				}

				items = unprocessed;
				await new Promise((r) =>
					setTimeout(r, 2 ** attempt * 100 + Math.random() * 100),
				);
			}
		}
	}
}
