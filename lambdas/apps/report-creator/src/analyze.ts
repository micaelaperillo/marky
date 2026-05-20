import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";

import type { GeminiAnalysis, InputMessage, OutputReport } from "./types.js";

const responseSchema = {
    type: SchemaType.OBJECT,
    properties: {
        analysis: {
            type: SchemaType.OBJECT,
            properties: {
                summary: {
                    type: SchemaType.STRING,
                    description: "Comprehensive summary of the conversation"
                },
                main_topics: {
                    type: SchemaType.ARRAY,
                    description: "Top 3 main topics, percent must sum to 100",
                    items: {
                        type: SchemaType.OBJECT,
                        properties: {
                            topic: { type: SchemaType.STRING },
                            percent: { type: SchemaType.INTEGER }
                        },
                        required: ["topic", "percent"] as string[]
                    },
                    minItems: 3,
                    maxItems: 3
                }
            },
            required: ["summary", "main_topics"] as string[]
        },
        sentiment: {
            type: SchemaType.OBJECT,
            properties: {
                label: {
                    type: SchemaType.STRING,
                    enum: ["Positive", "Neutral", "Negative"] as string[]
                },
                score: { type: SchemaType.NUMBER }
            },
            required: ["label", "score"] as string[]
        },
        key_comments: {
            type: SchemaType.ARRAY,
            description: "Top 5 most relevant comments",
            items: {
                type: SchemaType.OBJECT,
                properties: {
                    text: { type: SchemaType.STRING },
                    author: { type: SchemaType.STRING },
                    score: { type: SchemaType.NUMBER },
                    created_at: { type: SchemaType.STRING }
                },
                required: ["text", "author", "score", "created_at"] as string[]
            },
            minItems: 1,
            maxItems: 5
        }
    },
    required: ["analysis", "sentiment", "key_comments"] as string[]
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
        "Return ONLY the JSON object. No prose."
    ].join("\n");
}

export async function analyze(
    apiKey: string,
    input: InputMessage
): Promise<OutputReport> {
    if (!input.posts || input.posts.length === 0) {
        throw new Error("InputMessage.posts is empty");
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        generationConfig: {
            responseMimeType: "application/json",
            responseSchema
        }
    });

    const postsBlock = input.posts.map((p) => JSON.stringify(p)).join("\n");

    const result = await model.generateContent(
        buildPrompt(input.topics, postsBlock)
    );

    const text = result.response.text();
    let parsed: GeminiAnalysis;
    try {
        parsed = JSON.parse(text) as GeminiAnalysis;
    } catch (err) {
        throw new Error(
            `Gemini returned non-JSON: ${(err as Error).message}\nRaw: ${text.slice(0, 500)}`,
            { cause: err }
        );
    }

    return {
        report_id: input.id,
        query: input.topics,
        fetchedAt: input.fetchedAt,
        analysis: parsed.analysis,
        sentiment: parsed.sentiment,
        key_comments: parsed.key_comments,
        posts_analyzed: input.posts.length,
        generated_at: new Date().toISOString()
    };
}
