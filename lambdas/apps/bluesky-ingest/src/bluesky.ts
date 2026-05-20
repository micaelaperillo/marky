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
        password: process.env.BLUESKY_APP_PASSWORD!
    });

    return agent;
}

export async function searchBlueSky(campaign: {
    id: string;
    topics: string[];
}): Promise<BlueSkyResult> {
    const agent = await getAgent();

    const fetchedAt = new Date().toISOString();
    const response = await agent.app.bsky.feed.searchPosts({
        // Topics, by design, will always have at least 1 topic
        q: "+" + campaign.topics.join(" +"),
        limit: 25
    });

    const posts = response.data.posts.map((post) => {
        const record = post.record as { text: string; createdAt: string };
        return {
            uri: post.uri,
            text: record.text,
            user: post.author.handle,
            avatar: post.author.avatar,
            date: record.createdAt,
            likeCount: post.likeCount ?? 0,
            repostCount: post.repostCount ?? 0
        } satisfies BlueSkyPost;
    });

    return {
        ...campaign,
        fetchedAt,
        posts
    };
}
