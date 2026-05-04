import type { NextFunction, Request, Response } from "express";

export function requireAuth(req: Request, res: Response, next: NextFunction) {
	const userId = req.signedCookies?.user_id;
	if (!userId) {
		return res.status(401).json({ error: "Not authenticated" });
	}
	res.locals.userId = userId;
	next();
}
