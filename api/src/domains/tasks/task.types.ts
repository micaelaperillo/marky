import z from "zod";

export const TaskInputSchema = z.object({
	date: z.string(),
	schedule: z.string(),
	topic: z.string(),
});

export type TaskInput = z.infer<typeof TaskInputSchema>;
