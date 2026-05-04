import type { IAuthService } from "./interfaces/auth.service.js";

export class AuthService implements IAuthService {
	login(id: string): { userId: string } {
		return { userId: id };
	}

	me(userId: string): { userId: string } {
		return { userId };
	}
}
