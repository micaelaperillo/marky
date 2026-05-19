import { AtpAgent } from "@atproto/api";

export interface BlueSkyPost {
    uri: string;
    text: string;
    authorHandle: string;
    indexedAt: string;
    likeCount: number;
    repostCount: number;
}

export interface BlueSkyResult {
    campaignId: string;
    topic: string;
    posts: BlueSkyPost[];
    fetchedAt: string;
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
}): Promise<BlueSkyResult[]> {
    const a = await getAgent();
    return Promise.all(
        campaign.topics.map((topic) => searchTopic(a, campaign.id, topic)),
    );
}

async function searchTopic(
    a: AtpAgent,
    campaignId: string,
    topic: string,
): Promise<BlueSkyResult> {
    const response = await a.app.bsky.feed.searchPosts({
        q: topic,
        limit: 25,
    });

    const posts: BlueSkyPost[] = response.data.posts.map((post) => ({
        uri: post.uri,
        text: (post.record as { text: string }).text,
        authorHandle: post.author.handle,
        indexedAt: post.indexedAt,
        likeCount: post.likeCount ?? 0,
        repostCount: post.repostCount ?? 0,
    }));

    return {
        campaignId,
        topic,
        posts,
        fetchedAt: new Date().toISOString(),
    };
}
