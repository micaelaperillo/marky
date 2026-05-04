import { requireAuth } from "@shared/middleware/auth.js";
import type { Request, Response } from "express";
import { Router } from "express";

export class ExpressAuthController {
	readonly router: Router;

	constructor() {
		this.router = Router();
		this.router.get("/me", requireAuth, this.me.bind(this));
	}

	me(_req: Request, res: Response): void {
		res.json({ userId: res.locals.userId });
	}
}
