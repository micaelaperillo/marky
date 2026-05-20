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