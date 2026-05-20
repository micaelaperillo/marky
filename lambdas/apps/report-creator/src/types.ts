export type BlueskyPost = {
    user: string;
    text: string;
    avatar: string;
    date: string;
};

export type TimeWindow = {
    from: string;
    to: string;
};

export type InputMessage = {
    report_id: string;
    query: string;
    posts: BlueskyPost[];
    time_window?: TimeWindow;
};

export type MainTopic = {
    topic: string;
    percent: number;
};

export type SentimentLabel = "Positive" | "Neutral" | "Negative";

export type Sentiment = {
    label: SentimentLabel;
    score: number;
};

export type KeyComment = {
    text: string;
    author: string;
    score: number;
    created_at: string;
};

export type GeminiAnalysis = {
    analysis: {
        summary: string;
        main_topics: MainTopic[];
    };
    sentiment: Sentiment;
    key_comments: KeyComment[];
};

export type OutputReport = GeminiAnalysis & {
    report_id: string;
    query: string;
    time_window?: TimeWindow;
    posts_analyzed: number;
    generated_at: string;
};
