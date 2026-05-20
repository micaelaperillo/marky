import {
	CognitoIdentityProviderClient,
	GetUserCommand,
} from "@aws-sdk/client-cognito-identity-provider";
import { errorMiddleware } from "@shared/express/errors";
import { authenticated } from "@shared/service/cognito";
import express from "express";

const cognito = new CognitoIdentityProviderClient({});

const app = express();

app.use(express.json());

app.route("/me").get(authenticated, async (req, res, next) => {
	try {
		const token = req.headers.authorization!.slice("Bearer ".length);
		const { UserAttributes } = await cognito.send(
			new GetUserCommand({ AccessToken: token }),
		);
		const email = UserAttributes?.find((a) => a.Name === "email")?.Value;

		res.json({
			email,
			id: res.locals.userId,
		});
	} catch (err) {
		next(err);
	}
});

app.use(errorMiddleware);

export default app;
