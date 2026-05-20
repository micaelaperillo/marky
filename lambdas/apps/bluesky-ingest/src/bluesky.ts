import { AtpAgent } from "@atproto/api";

export interface BlueSkyPost {
	uri: string;
	text: string;
	date: string;
	user: string;
	avatar?: string;
	likeCount: number;
	repostCount: number;
}

export interface BlueSkyResult {
	id: string;
	topics: string[];
	fetchedAt: string;
	posts: BlueSkyPost[];
}

let agent: AtpAgent | null = null;

async function getAgent(): Promise<AtpAgent> {
	if (agent) return agent;

	agent = new AtpAgent({ service: "https://bsky.social" });
	await agent.login({
		identifier: process.env.BLUESKY_IDENTIFIER!,
		password: process.env.BLUESKY_APP_PASSWORD!,
	});

	return agent;
}

export async function searchBlueSky(campaign: {
	id: string;
	topics: string[];
}): Promise<BlueSkyResult> {
	try {
		return await doSearch(campaign);
	} catch (err) {
		if (
			err instanceof Error &&
			(err.message.includes("auth") ||
				err.message.includes("token") ||
				err.message.includes("Invalid"))
		) {
			agent = null;
			return await doSearch(campaign);
		}
		throw err;
	}
}

async function doSearch(campaign: {
	id: string;
	topics: string[];
}): Promise<BlueSkyResult> {
	const a = await getAgent();

	const fetchedAt = new Date().toISOString();
	const response = await a.app.bsky.feed.searchPosts({
		limit: 25,
		// Topics, by design, will always have at least 1 topic
		q: "+" + campaign.topics.join(" +"),
	});

	const posts = response.data.posts.map((post) => {
		const record = post.record as { text: string; createdAt: string };
		return {
			avatar: post.author.avatar,
			date: record.createdAt,
			likeCount: post.likeCount ?? 0,
			repostCount: post.repostCount ?? 0,
			text: record.text,
			uri: post.uri,
			user: post.author.handle,
		} satisfies BlueSkyPost;
	});

	return {
		...campaign,
		fetchedAt,
		posts,
	};
}
