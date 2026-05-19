import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";

import { ApiError } from "@shared/errors/api";

export function errorMiddleware(
    err: unknown,
    _req: Request,
    res: Response,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _next: NextFunction
) {
    if (err instanceof ZodError) {
        return res.status(400).json({
            error: "Validation failed",
            issues: err.issues.map((i) => ({
                message: i.message,
                path: i.path
            }))
        });
    }

    if (err instanceof ApiError) {
        return res.status(err.statusCode).json({ error: err.message });
    }

    console.error(err, "Unhandled error");
    res.status(500).json({ error: "Internal Server Error" });
}
