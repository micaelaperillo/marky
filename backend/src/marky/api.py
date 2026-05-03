import uvicorn
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timezone
from textblob import TextBlob
from google import genai
from typing import List
import logging

from marky.config import Settings
from marky.services.polymarket import GammaClient

# Setup logging
settings = Settings()
logging.basicConfig(level=settings.log_level)
logger = logging.getLogger("marky.api")

app = FastAPI(title="Marky API")

# Enable CORS for local development (SvelteKit)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def analyze_sentiment(text: str):
    if not text:
        return 0.0, 0.0
    blob = TextBlob(text)
    return blob.sentiment.polarity, blob.sentiment.subjectivity

@app.get("/api/analyze")
async def analyze(
    start: str = Query(..., description="Start date in ISO format"),
    end: str = Query(..., description="End date in ISO format"),
    topics: str = Query(..., description="Comma-separated list of topics")
):
    try:
        start_dt = datetime.fromisoformat(start).replace(tzinfo=timezone.utc)
        end_dt = datetime.fromisoformat(end).replace(tzinfo=timezone.utc)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use ISO format (YYYY-MM-DD)")

    topic_list = [t.strip() for t in topics.split(",") if t.strip()]
    if not topic_list:
        raise HTTPException(status_code=400, detail="No topics provided")

    gamma = GammaClient(
        base_url=settings.gamma_base_url,
        timeout=settings.gamma_timeout_seconds,
        max_retries=settings.gamma_max_retries,
    )

    all_data = []

    for topic in topic_list:
        logger.info(f"Fetching data for topic: {topic}")
        search = gamma.public_search(topic)
        event_ids = [e.id for e in search.events]
        
        if not event_ids:
            continue

        events = gamma.get_events(
            ids=event_ids,
            start_date_min=start_dt,
            end_date_max=end_dt,
        )

        for event in events:
            event_sentiment_polarity, event_sentiment_subjectivity = analyze_sentiment((event.title or "") + " " + (event.description or ""))
            
            comments_data = []
            if event.comments_enabled:
                for comment in gamma.iter_event_comments(event.id, start_dt, end_dt):
                    polarity, subjectivity = analyze_sentiment(comment.body or "")
                    comments_data.append({
                        "content": comment.body,
                        "polarity": polarity,
                        "subjectivity": subjectivity
                    })
            
            # Average of comment sentiment
            avg_comment_polarity = sum(c["polarity"] for c in comments_data) / len(comments_data) if comments_data else 0.0
            
            total_volume = sum(m.volume for m in event.markets)
            
            all_data.append({
                "topic": topic,
                "event_title": event.title,
                "event_description": event.description,
                "event_sentiment": event_sentiment_polarity,
                "comments_count": len(comments_data),
                "avg_comment_sentiment": avg_comment_polarity,
                "volume": total_volume
            })

    if not all_data:
        return {"report": "No relevant Polymarket events found for the given topics and date range."}

    # Generate LLM Report
    if not settings.gemini_api_key:
        return {
            "report": "GEMINI_API_KEY not configured. Here is the raw data summary:\n\n" + \
                      "\n".join([f"- {d['event_title']} (Sentiment: {d['event_sentiment']:.2f}, Comments: {d['comments_count']})" for d in all_data])
        }

    client = genai.Client(api_key=settings.gemini_api_key)
    
    prompt = f"""
    Analyze the following Polymarket data for the period {start} to {end} regarding topics: {topics}.
    
    Data:
    {all_data}
    
    Provide a cohesive, professional analysis of what's been going on. 
    Use the sentiment scores (polarity from -1 to 1) and market details to explain the public perception and market confidence.
    Format the output nicely in Markdown.
    """

    response = client.models.generate_content(
        model="gemini-3-flash-preview",
        contents=prompt
    )

    return {"report": response.text}

def main():
    uvicorn.run("marky.api:app", host="0.0.0.0", port=8000, reload=True)

if __name__ == "__main__":
    main()
