import type { TaskInput } from "../task.types.js";

export interface ITaskRepository {
	batchCreate(tasks: TaskInput[]): Promise<void>;
}
