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
  --endpoint-url http://127.0.0.1:8000 \
  --region us-east-1 \
  --no-cli-pager \
  --item '{
    "PK": { "S": "CAMPAIGN#115efe53-e239-460c-876a-ed6d72091f8a" },
    "SK": { "S": "REPORT#2026-05-18T17:30:00.123Z" },

    "campaign_id": { "S": "115efe53-e239-460c-876a-ed6d72091f8a" },
    "timestamp": { "S": "2025-05-18T17:30:00.123Z" },
    "sentiment": { "N": "0.95" },

    "report": {
      "M": {
        "analysis": {
          "M": {
            "summary": {
              "S": "Comprehensive summary..."
            },

            "main_topics": {
              "L": [
                {
                  "M": {
                    "topic": { "S": "Topic 1" },
                    "percent": { "N": "45" }
                  }
                },
                {
                  "M": {
                    "topic": { "S": "Topic 2" },
                    "percent": { "N": "35" }
                  }
                },
                {
                  "M": {
                    "topic": { "S": "Topic 3" },
                    "percent": { "N": "20" }
                  }
                }
              ]
            }
          }
        },

        "sentiment": {
          "M": {
            "label": {
              "S": "positive"
            },
            "score": {
              "N": "0.95"
            }
          }
        },

        "key_comments": {
          "L": [
            {
              "M": {
                "text": {
                  "S": "Comment text..."
                },
                "author": {
                  "S": "username.bsky.social"
                },
                "score": {
                  "N": "0.75"
                },
                "created_at": {
                  "S": "2025-05-19T10:00:00.123Z"
                }
              }
            }
          ]
        },

        "posts_analyzed": {
          "N": "10"
        },

        "generated_at": {
          "S": "2025-05-19T15:30:00.123Z"
        }
      }
    }
  }'