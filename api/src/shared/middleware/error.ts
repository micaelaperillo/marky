import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";
import { ApiError } from "../errors.js";
import { logger } from "../logger.js";

export function errorMiddleware(
	err: unknown,
	_req: Request,
	res: Response,
	_next: NextFunction,
) {
	if (err instanceof ZodError) {
		res.status(400).json({
			error: "Validation failed",
			issues: err.issues.map((i) => ({ message: i.message, path: i.path })),
		});
		return;
	}

	if (err instanceof ApiError) {
		res.status(err.statusCode).json({ error: err.message });
		return;
	}

	logger.error(err, "Unhandled error");
	res.status(500).json({ error: "Internal Server Error" });
}
