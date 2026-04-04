import json
import os
import sys
from textblob import TextBlob

def analyze_sentiment(text):
    if not text:
        return 0, 0
    blob = TextBlob(text)
    return blob.sentiment.polarity, blob.sentiment.subjectivity

def main():
    data_path = "data/polymarket_tech_data.json"
    if not os.path.exists(data_path):
        # TODO: this will come from the S3 bucket
        data_path = "backend/data/polymarket_tech_data.json"
        if not os.path.exists(data_path):
            print(f"Error: Data file not found at {data_path}", file=sys.stderr)
            sys.exit(1)

    with open(data_path, "r") as f:
        data = json.load(f)

    markets = data.get("markets", [])
    results = []

    print(f"Analyzing sentiment for {len(markets)} markets\n")

    for market in markets:
        question = market.get("question", "")
        description = market.get("description", "")
        
        polarity, subjectivity = analyze_sentiment(question)
        
        # Market Confidence (Price probability)
        try:
            prices = json.loads(market.get("outcomePrices", "[]"))
            yes_price = float(prices[0]) if len(prices) > 0 else 0.5
        except (ValueError, IndexError, TypeError):
            yes_price = 0.5
        
        # Determine sentiment category
        # If yes_price > 0.5, the market thinks it WILL happen.
        # If polarity > 0, the phrasing is positive.
        
        results.append({
            "question": question,
            "nlp_polarity": polarity,
            "nlp_subjectivity": subjectivity,
            "market_probability": yes_price,
            "volume": float(market.get("volume", 0))
        })

    results.sort(key=lambda x: x["nlp_polarity"], reverse=True)

    print(f"{'Question':<60} | {'Polarity':<10} | {'Prob':<5}")
    print("-" * 85)
    for res in results[:10]: # Top 10 Positive
        print(f"{res['question'][:57] + '...':<60} | {res['nlp_polarity']:>10.2f} | {res['market_probability']:>5.2f}")

    print("\n" + "-" * 85 + "\n")

    results.sort(key=lambda x: x["market_probability"], reverse=True)
    print(f"{'Question':<60} | {'Prob':<10} | {'Polarity':<5}")
    print("-" * 85)
    for res in results[:10]: # Top 10 most likely to happen
        print(f"{res['question'][:57] + '...':<60} | {res['market_probability']:>10.2f} | {res['nlp_polarity']:>5.2f}")

    avg_polarity = sum(r['nlp_polarity'] for r in results) / len(results) if results else 0
    avg_prob = sum(r['market_probability'] for r in results) / len(results) if results else 0
    
    print("\n" + "=" * 85)
    print(f"SUMMARY STATISTICS")
    print(f"Average NLP Sentiment (Polarity): {avg_polarity:.3f} (-1.0 to 1.0)")
    print(f"Average Market Probability:       {avg_prob:.3f} (0.0 to 1.0)")
    print("=" * 85)

if __name__ == "__main__":
    main()