import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";

import type { GeminiAnalysis, InputMessage, OutputReport } from "./types.js";

const responseSchema = {
	properties: {
		analysis: {
			properties: {
				main_topics: {
					description: "Top 3 main topics, percent must sum to 100",
					items: {
						properties: {
							percent: { type: SchemaType.INTEGER },
							topic: { type: SchemaType.STRING },
						},
						required: ["topic", "percent"] as string[],
						type: SchemaType.OBJECT,
					},
					maxItems: 3,
					minItems: 3,
					type: SchemaType.ARRAY,
				},
				summary: {
					description: "Comprehensive summary of the conversation",
					type: SchemaType.STRING,
				},
			},
			required: ["summary", "main_topics"] as string[],
			type: SchemaType.OBJECT,
		},
		key_comments: {
			description: "Top 5 most relevant comments",
			items: {
				properties: {
					author: { type: SchemaType.STRING },
					created_at: { type: SchemaType.STRING },
					score: { type: SchemaType.NUMBER },
					text: { type: SchemaType.STRING },
				},
				required: ["text", "author", "score", "created_at"] as string[],
				type: SchemaType.OBJECT,
			},
			maxItems: 5,
			minItems: 1,
			type: SchemaType.ARRAY,
		},
		sentiment: {
			properties: {
				label: {
					enum: ["Positive", "Neutral", "Negative"] as string[],
					type: SchemaType.STRING,
				},
				score: { type: SchemaType.NUMBER },
			},
			required: ["label", "score"] as string[],
			type: SchemaType.OBJECT,
		},
	},
	required: ["analysis", "sentiment", "key_comments"] as string[],
	type: SchemaType.OBJECT,
} as const;

function buildPrompt(topics: string[], postsBlock: string): string {
	return [
		"You analyze Bluesky social-media posts. Your output must be valid JSON matching the schema you've been given.",
		"",
		`Topic of analysis: "${topics.join(",")}"`,
		"",
		"Posts (one JSON object per line):",
		postsBlock,
		"",
		"Tasks:",
		"1. Detect overall sentiment across the whole conversation. Label = Positive | Neutral | Negative. Score = -1 (very negative) to 1 (very positive).",
		"2. Identify the top 3 main topics being discussed. Each has a percent (integer). The three percents MUST sum to 100.",
		"3. Pick the top 5 most relevant/impactful comments. Preserve the original text, author handle, and ISO 8601 created_at. Score each comment -1..1.",
		"4. Write a comprehensive summary in English. Detect nuance, sarcasm, criticism, praise.",
		"",
		"Return ONLY the JSON object. No prose.",
	].join("\n");
}

export async function analyze(
	apiKey: string,
	input: InputMessage,
): Promise<OutputReport> {
	if (!input.posts || input.posts.length === 0) {
		throw new Error("InputMessage.posts is empty");
	}

	const genAI = new GoogleGenerativeAI(apiKey);
	const model = genAI.getGenerativeModel({
		generationConfig: {
			responseMimeType: "application/json",
			responseSchema,
		},
		model: "gemini-2.5-flash",
	});

	const postsBlock = input.posts.map((p) => JSON.stringify(p)).join("\n");

	const result = await model.generateContent(
		buildPrompt(input.topics, postsBlock),
	);

	const text = result.response.text();
	let parsed: GeminiAnalysis;
	try {
		parsed = JSON.parse(text) as GeminiAnalysis;
	} catch (err) {
		throw new Error(
			`Gemini returned non-JSON: ${(err as Error).message} (length=${text.length})`,
			{ cause: err },
		);
	}

	return {
		analysis: parsed.analysis,
		fetchedAt: input.fetchedAt,
		generated_at: new Date().toISOString(),
		id: input.id,
		key_comments: parsed.key_comments,
		posts_analyzed: input.posts.length,
		query: input.topics,
		sentiment: parsed.sentiment,
	};
}
