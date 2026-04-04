import requests
import json
import argparse
import sys
import os

def fetch_data(endpoint, params):
    url = f"https://gamma-api.polymarket.com/{endpoint}"
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from {endpoint}: {e}", file=sys.stderr)
        return []

def main():
    parser = argparse.ArgumentParser(description="Ingest technology-related data from Polymarket GAMMA API.")
    parser.add_argument("--output", help="Output JSON file path", default="data/polymarket_tech_data.json")
    parser.add_argument("--limit", type=int, default=100, help="Limit per tag/status (default: 100)")
    args = parser.parse_args()

    TECH_TAG_IDS = [22, 439, 1401]
    
    all_events = {}
    all_markets = {}
    
    print(f"Fetching data for tags: {TECH_TAG_IDS}...")
    
    for tag_id in TECH_TAG_IDS:
        # 1. Fetch LIVE markets
        print(f"Fetching LIVE data for tag {tag_id}...")
        params_live = {
            "tag_id": tag_id,
            "active": "true",
            "closed": "false",
            "limit": args.limit
        }
        
        # Events (Live)
        events_live = fetch_data("events", params_live)
        for e in events_live: all_events[e['id']] = e
        
        # Markets (Live)
        markets_live = fetch_data("markets", params_live)
        for m in markets_live: all_markets[m['id']] = m

        # 2. Fetch some CLOSED markets for historical context
        print(f"Fetching CLOSED data for tag {tag_id}...")
        params_closed = {
            "tag_id": tag_id,
            "active": "true",
            "closed": "true",
            "limit": 50 # Just get some historical context
        }
        events_closed = fetch_data("events", params_closed)
        for e in events_closed: all_events[e['id']] = e
        
        markets_closed = fetch_data("markets", params_closed)
        for m in markets_closed: all_markets[m['id']] = m
    
    data = {
        "events": list(all_events.values()),
        "markets": list(all_markets.values())
    }

    # Verify we actually got live data
    live_count = sum(1 for m in data['markets'] if not m.get('closed'))
    print(f"Total Unique: {len(data['events'])} events and {len(data['markets'])} markets ({live_count} live).")
    
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w") as f:
        json.dump(data, f, indent=2)
    
    print(f"Data successfully saved to {args.output}")

if __name__ == "__main__":
    main()
