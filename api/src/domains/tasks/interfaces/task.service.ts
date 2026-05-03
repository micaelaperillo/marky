export interface ITaskService {
	createForDateRange(
		topics: string[],
		start: string,
		end: string,
		today?: string,
	): Promise<void>;
}
