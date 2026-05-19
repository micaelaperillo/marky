import type { NextFunction, Request, Response } from "express";
import type { z } from "zod";

export function body(schema: z.ZodSchema) {
    return (req: Request, _res: Response, next: NextFunction) => {
        req.body = schema.parse(req.body);
        next();
    };
}

export function params(schema: z.ZodSchema) {
    return (req: Request, _res: Response, next: NextFunction) => {
        req.params = schema.parse(req.params) as typeof req.params;
        next();
    };
}
