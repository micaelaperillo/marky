export interface IAuthService {
	login(id: string): { userId: string };
	me(userId: string): { userId: string };
}
