import requests
import json
import argparse
import sys

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
    parser.add_argument("--limit", type=int, default=100, help="Limit the number of items to fetch (default: 100)")
    args = parser.parse_args()

    TECH_TAG_ID = 22
    
    print(f"Fetching technology-related events and markets (Tag ID: {TECH_TAG_ID})")
    
    params = {
        "tag_id": TECH_TAG_ID,
        "active": "true",
        "limit": args.limit
    }

    print("Fetching events")
    events = fetch_data("events", params)
    
    print("Fetching markets")
    markets = fetch_data("markets", params)
    
    data = {
        "events": events,
        "markets": markets
    }

    print(f"Fetched {len(events)} events and {len(markets)} markets.")
    
    with open(args.output, "w") as f:
        json.dump(data, f, indent=2)
    
    print(f"Data successfully saved to {args.output}")

if __name__ == "__main__":
    main()
