# Marky

Social media analytics platform — monitors Bluesky posts and generates AI-powered sentiment reports using Google Gemini.

## Architecture

- **Frontend**: SvelteKit deployed to S3 via API Gateway
- **Backend API**: Lambda functions (Express via serverless-http)
- **Authentication**: Amazon Cognito
- **Data Pipeline**: SQS FIFO → SNS FIFO → Lambda (event-driven)
- **Storage**: S3 (raw posts) + DynamoDB (reports) + RDS PostgreSQL (campaigns)
- **AI**: Google Gemini for content analysis and report generation

## Deployment (GitHub Actions)

### Required Secrets

Configure in **Settings → Secrets and variables → Actions**:

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS Academy access key |
| `AWS_SECRET_ACCESS_KEY` | AWS Academy secret key |
| `AWS_SESSION_TOKEN` | AWS Academy session token (required) |
| `GEMINI_API_KEY` | Google Gemini API key for report generation |
| `BLUESKY_IDENTIFIER` | Bluesky handle (e.g., handle.bsky.social) |
| `BLUESKY_APP_PASSWORD` | Bluesky app-specific password |

### Deploy

cd lambdas
pnpm i
pnpm -r build
cd ../terraform
terraform init
terraform apply
cd ..
make deploy-frontend

### Destroy

1. Go to **Actions** → **Destroy Infrastructure**
2. Click **Run workflow**
3. Enter `destroy` in the confirmation prompt

### Access

After deploy, the frontend is available at:
```
https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/
```

## Project Structure

```
├── .github/workflows/     # CI/CD pipelines (workflow_dispatch)
├── terraform/             # Infrastructure as Code
├── frontend/              # SvelteKit web application
└── lambdas/               # Lambda function source code (pnpm workspaces)
```

## AWS Academy Notes

- Uses LabRole (limited IAM permissions)
- Session credentials expire every 4 hours
- No KMS custom keys available
