# Marky

Monitoring the Situation

### Data Ingestion

In `backend/`
```bash
uv run ingest_polymarket.py
```

### Run API
In `backend/`
```bash
uv run fastapi run api.py
```

See [Example Route](http://localhost:8000/markets?live_only=false)