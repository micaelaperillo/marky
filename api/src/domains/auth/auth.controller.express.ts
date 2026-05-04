import { env } from "@shared/config/env.js";
import { requireAuth } from "@shared/middleware/auth.js";
import { validateBody } from "@shared/middleware/validate.js";
import type { NextFunction, Request, Response } from "express";
import { Router } from "express";
import { LoginSchema } from "./auth.validation.js";
import type { IAuthService } from "./interfaces/auth.service.js";

export class ExpressAuthController {
	readonly router: Router;
	private service: IAuthService;

	constructor(service: IAuthService) {
		this.service = service;
		this.router = Router();
		this.router.post(
			"/login",
			validateBody(LoginSchema),
			this.login.bind(this),
		);
		this.router.post("/logout", this.logout.bind(this));
		this.router.get("/me", requireAuth, this.me.bind(this));
	}

	login(req: Request, res: Response, _next: NextFunction): void {
		const session = this.service.login(req.body.id);

		res.cookie("user_id", session.userId, {
			httpOnly: true,
			path: "/",
			sameSite: "lax",
			secure: env.isProduction,
			signed: true,
		});

		res.json(session);
	}

	logout(_req: Request, res: Response): void {
		res.clearCookie("user_id", {
			httpOnly: true,
			path: "/",
			sameSite: "lax",
			secure: env.isProduction,
		});
		res.json({ success: true });
	}

	me(_req: Request, res: Response): void {
		res.json(this.service.me(res.locals.userId));
	}
}
