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
