aws dynamodb create-table \
  --table-name reports \
  --attribute-definitions \
    AttributeName=PK,AttributeType=S \
    AttributeName=SK,AttributeType=S \
  --key-schema \
    AttributeName=PK,KeyType=HASH \
    AttributeName=SK,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://localhost:8000 \
  --region us-east-1


aws dynamodb put-item \
  --table-name reports \
  --endpoint-url http://localhost:8000 \
  --region us-east-1 \
  --item '{
    "PK": { "S": "CAMPAIGN#123" },
    "SK": { "S": "REPORT#2026-05-19T01:00:00.000Z" },
    "campaign_id": { "S": "123" },
    "timestamp": { "S": "2026-05-19T01:00:00.000Z" },
    "sentiment": { "N": "35.9" },
    "report": { "S": "{\"summary\":\"Resumen de prueba\",\"topics\":[]}" }
  }'