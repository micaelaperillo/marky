import { CognitoEnvSchema } from "@shared/config";
import { CognitoJwtVerifier } from "aws-jwt-verify";
import type { NextFunction, Request, Response } from "express";

const env = CognitoEnvSchema.parse(process.env);

const verifier = CognitoJwtVerifier.create({
	clientId: env.cognito.clientId,
	tokenUse: "access",
	userPoolId: env.cognito.userPoolId,
});

export async function authenticated(
	req: Request,
	res: Response,
	next: NextFunction,
) {
	const header = req.headers.authorization;

	if (!header?.startsWith("Bearer ")) {
		res.status(401).json({
			error: "Missing or invalid Authorization header",
		});

		return;
	}

	try {
		const payload = await verifier.verify(header.slice("Bearer ".length));

		if (!payload.sub) {
			res.status(401).json({ error: "Invalid token: missing subject" });
			return;
		}

		res.locals.userId = payload.sub;
		return next();
	} catch (err) {
		const name = err instanceof Error ? err.constructor.name : "";

		if (name.startsWith("Jwt") || name.startsWith("Cognito")) {
			res.status(401).json({ error: "Invalid or expired token" });
			return;
		}

		return next(err);
	}
}
