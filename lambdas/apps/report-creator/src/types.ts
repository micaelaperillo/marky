export type BlueskyPost = {
	user: string;
	text: string;
	avatar?: string;
	date: string;
	uri?: string;
	likeCount?: number;
	repostCount?: number;
};

export type InputMessage = {
	id: string;
	topics: string[];
	posts: BlueskyPost[];
	fetchedAt: string;
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
	id: string;
	query: string[];
	fetchedAt: string;
	posts_analyzed: number;
	generated_at: string;
};
