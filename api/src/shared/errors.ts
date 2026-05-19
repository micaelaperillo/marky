export abstract class ApiError extends Error {
	abstract get statusCode(): number;

	constructor(message: string) {
		super(message);
		this.name = this.constructor.name;
	}
}
