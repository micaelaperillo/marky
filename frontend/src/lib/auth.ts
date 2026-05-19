import {
	AuthenticationDetails,
	CognitoUser,
	CognitoUserPool,
	type CognitoUserSession
} from 'amazon-cognito-identity-js';

const poolData = {
	ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
	UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID
};

const userPool = new CognitoUserPool(poolData);

function getCognitoUser(email: string): CognitoUser {
	return new CognitoUser({ Pool: userPool, Username: email });
}

export function signUp(email: string, password: string): Promise<void> {
	return new Promise((resolve, reject) => {
		userPool.signUp(email, password, [], [], (err) => {
			if (err) reject(err);
			else resolve();
		});
	});
}

export function confirmSignUp(email: string, code: string): Promise<void> {
	const user = getCognitoUser(email);
	return new Promise((resolve, reject) => {
		user.confirmRegistration(code, false, (err) => {
			if (err) reject(err);
			else resolve();
		});
	});
}

export function signIn(email: string, password: string): Promise<CognitoUserSession> {
	const user = getCognitoUser(email);
	const authDetails = new AuthenticationDetails({
		Password: password,
		Username: email
	});

	return new Promise((resolve, reject) => {
		user.authenticateUser(authDetails, {
			newPasswordRequired: () => reject(new Error('Password change required')),
			onFailure: (err) => reject(err),
			onSuccess: (session) => resolve(session)
		});
	});
}

export function getAccessToken(): Promise<string | null> {
	const user = userPool.getCurrentUser();
	if (!user) return Promise.resolve(null);
	return new Promise((resolve) => {
		user.getSession((err: Error | null, session: CognitoUserSession | null) => {
			if (err || !session || !session.isValid()) {
				resolve(null);
				return;
			}
			resolve(session.getAccessToken().getJwtToken());
		});
	});
}

export function getUserEmail(): Promise<string | null> {
	const user = userPool.getCurrentUser();
	if (!user) return Promise.resolve(null);
	return new Promise((resolve) => {
		user.getSession((err: Error | null, session: CognitoUserSession | null) => {
			if (err || !session || !session.isValid()) {
				resolve(null);
				return;
			}
			const payload = session.getIdToken().decodePayload();
			resolve((payload.email as string) ?? null);
		});
	});
}

export function signOut(): void {
	const user = userPool.getCurrentUser();
	if (user) user.signOut();
}

export function forgotPassword(email: string): Promise<void> {
	const user = getCognitoUser(email);
	return new Promise((resolve, reject) => {
		user.forgotPassword({
			onFailure: (err) => reject(err),
			onSuccess: () => resolve()
		});
	});
}

export function confirmForgotPassword(
	email: string,
	code: string,
	newPassword: string
): Promise<void> {
	const user = getCognitoUser(email);
	return new Promise((resolve, reject) => {
		user.confirmPassword(code, newPassword, {
			onFailure: (err) => reject(err),
			onSuccess: () => resolve()
		});
	});
}
