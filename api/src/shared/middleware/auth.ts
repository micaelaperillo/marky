import { env } from "@shared/config/env.js";
import { CognitoJwtVerifier } from "aws-jwt-verify";
import type { NextFunction, Request, Response } from "express";

const verifier = CognitoJwtVerifier.create({
	clientId: env.cognito.clientId,
	tokenUse: "access",
	userPoolId: env.cognito.userPoolId,
});

export async function requireAuth(
	req: Request,
	res: Response,
	next: NextFunction,
): Promise<void> {
	const header = req.headers.authorization;
	if (!header?.startsWith("Bearer ")) {
		res.status(401).json({ error: "Missing or invalid Authorization header" });
		return;
	}

	try {
		const payload = await verifier.verify(header.slice(7));
		if (!payload.sub) {
			res.status(401).json({ error: "Invalid token: missing subject" });
			return;
		}
		res.locals.userId = payload.sub;
		next();
	} catch (err) {
		const name = err instanceof Error ? err.constructor.name : "";
		if (name.startsWith("Jwt") || name.startsWith("Cognito")) {
			res.status(401).json({ error: "Invalid or expired token" });
			return;
		}
		next(err);
	}
}
