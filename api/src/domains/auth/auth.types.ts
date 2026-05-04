import type z from "zod";
import type { LoginSchema } from "./auth.validation.js";

export type LoginInput = z.infer<typeof LoginSchema>;
