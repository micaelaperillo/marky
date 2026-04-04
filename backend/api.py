import json
import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from textblob import TextBlob
import uvicorn

app = FastAPI(title="Polymarket Tech Sentiment API")

# Enable CORS for frontend dashboard
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_PATH = "data/polymarket_tech_data.json"

def get_data():
    if not os.path.exists(DATA_PATH):
        # Try local path for dev
        local_path = os.path.join(os.path.dirname(__file__), "data/polymarket_tech_data.json")
        if not os.path.exists(local_path):
            raise HTTPException(status_code=404, detail="Data file not found. Run the ingestion script first.")
        return local_path
    return DATA_PATH

def analyze_sentiment(text: str):
    if not text:
        return 0.0, 0.0
    blob = TextBlob(text)
    return blob.sentiment.polarity, blob.sentiment.subjectivity

@app.get("/")
def read_root():
    return {"status": "online", "message": "Polymarket Tech Sentiment API is running"}

@app.get("/markets")
def get_markets(limit: int = 100, live_only: bool = True):
    path = get_data()
    with open(path, "r") as f:
        data = json.load(f)
    
    raw_markets = data.get("markets", [])
    
    # Filter for LIVE markets (Open for betting)
    if live_only:
        markets = [m for m in raw_markets if m.get("active") == True and m.get("closed") == False]
    else:
        markets = raw_markets
        
    markets = markets[:limit]
    results = []
    
    for m in markets:
        # Better NLP: Analyze Question + Description
        # Descriptions often contain more nuanced sentiment than the clinical question
        full_text = f"{m.get('question', '')}. {m.get('description', '')}"
        polarity, subjectivity = analyze_sentiment(full_text)
        
        try:
            prices = json.loads(m.get("outcomePrices", "[]"))
            prob = float(prices[0]) if len(prices) > 0 else 0.5
        except:
            prob = 0.5
            
        results.append({
            "id": m.get("id"),
            "question": m.get("question"),
            "nlp_polarity": polarity,
            "nlp_subjectivity": subjectivity,
            "market_probability": prob,
            "volume": float(m.get("volume", 0)),
            "image": m.get("image"),
            "is_closed": m.get("closed", False)
        })
    
    return results

@app.get("/summary")
def get_summary(live_only: bool = True):
    path = get_data()
    with open(path, "r") as f:
        data = json.load(f)
    
    raw_markets = data.get("markets", [])
    if live_only:
        markets = [m for m in raw_markets if m.get("active") == True and m.get("closed") == False]
    else:
        markets = raw_markets

    if not markets:
        return {"error": "No live markets available", "total_raw": len(raw_markets)}
        
    total_polarity = 0
    total_prob = 0
    count = 0
    
    for m in markets:
        full_text = f"{m.get('question', '')}. {m.get('description', '')}"
        polarity, _ = analyze_sentiment(full_text)
        try:
            prices = json.loads(m.get("outcomePrices", "[]"))
            prob = float(prices[0]) if len(prices) > 0 else 0.5
        except:
            prob = 0.5
            
        total_polarity += polarity
        total_prob += prob
        count += 1
        
    avg_pol = total_polarity / count
    avg_prob = total_prob / count
    
    return {
        "total_markets": count,
        "avg_nlp_polarity": avg_pol,
        "avg_market_probability": avg_prob,
        "sentiment_label": "Neutral" if abs(avg_pol) < 0.1 else ("Positive" if avg_pol > 0 else "Negative"),
        "market_confidence": "Skeptical" if avg_prob < 0.3 else ("Moderate" if avg_prob < 0.6 else "Confident")
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
