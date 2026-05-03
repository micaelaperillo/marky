import z from "zod";

export const LoginSchema = z.object({
	id: z.string().min(1),
});
