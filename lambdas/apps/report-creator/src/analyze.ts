import { GoogleGenAI, Type } from "@google/genai";
import { GeminiEnvSchema } from "@shared/config";

import type { GeminiAnalysis, InputMessage, OutputReport } from "./types.js";

// Gemini frequently returns 503 (model overloaded). The new SDK retries the
// transient status codes (408/429/500/502/503/504) with exponential backoff
// internally; GEMINI_RETRY_ATTEMPTS tunes how many attempts (see GeminiEnvSchema
// for the bound rationale).
const env = GeminiEnvSchema.parse(process.env);

const responseSchema = {
	properties: {
		analysis: {
			properties: {
				main_topics: {
					description: "Top 3 main topics, percent must sum to 100",
					items: {
						properties: {
							percent: { type: Type.INTEGER },
							topic: { type: Type.STRING },
						},
						required: ["topic", "percent"] as string[],
						type: Type.OBJECT,
					},
					maxItems: 3,
					minItems: 3,
					type: Type.ARRAY,
				},
				summary: {
					description: "Comprehensive summary of the conversation",
					type: Type.STRING,
				},
			},
			required: ["summary", "main_topics"] as string[],
			type: Type.OBJECT,
		},
		key_comments: {
			description: "Top 5 most relevant comments",
			items: {
				properties: {
					author: { type: Type.STRING },
					created_at: { type: Type.STRING },
					score: { type: Type.NUMBER },
					text: { type: Type.STRING },
				},
				required: ["text", "author", "score", "created_at"] as string[],
				type: Type.OBJECT,
			},
			maxItems: 5,
			minItems: 1,
			type: Type.ARRAY,
		},
		sentiment: {
			properties: {
				label: {
					enum: ["Positive", "Neutral", "Negative"] as string[],
					type: Type.STRING,
				},
				score: { type: Type.NUMBER },
			},
			required: ["label", "score"] as string[],
			type: Type.OBJECT,
		},
	},
	required: ["analysis", "sentiment", "key_comments"] as string[],
	type: Type.OBJECT,
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

	const ai = new GoogleGenAI({
		apiKey,
		httpOptions: { retryOptions: { attempts: env.gemini.retryAttempts } },
	});

	const postsBlock = input.posts.map((p) => JSON.stringify(p)).join("\n");

	const response = await ai.models.generateContent({
		config: {
			responseMimeType: "application/json",
			responseSchema,
		},
		contents: buildPrompt(input.topics, postsBlock),
		model: env.gemini.model,
	});

	const text = response.text;
	if (text === undefined) {
		throw new Error("Gemini returned no text (response blocked or empty)");
	}

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
