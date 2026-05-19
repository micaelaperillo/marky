import dayjs from "dayjs";
import type { ITaskRepository } from "./interfaces/task.repository.js";
import type { ITaskService } from "./interfaces/task.service.js";
import type { TaskInput } from "./task.types.js";
import { TaskInputSchema } from "./task.types.js";

export class TaskService implements ITaskService {
	private repo: ITaskRepository;

	constructor(repo: ITaskRepository) {
		this.repo = repo;
	}

	async createForDateRange(
		topics: string[],
		start: string,
		end: string,
		today = dayjs().format("YYYY-MM-DD"),
	): Promise<void> {
		const tasks: TaskInput[] = [];
		let current = dayjs(start);
		const endDate = dayjs(end);

		while (current.isBefore(endDate)) {
			const dateStr = current.format("YYYY-MM-DD");
			for (const topic of topics) {
				tasks.push({ date: dateStr, schedule: today, topic });
			}
			current = current.add(1, "day");
		}

		const validated = tasks.map((t) => TaskInputSchema.parse(t));
		await this.repo.batchCreate(validated);
	}
}
