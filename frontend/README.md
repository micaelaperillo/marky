# Marky Frontend

SvelteKit SPA (adapter-static) with Svelte 5, Tailwind CSS, and Paraglide i18n.

## Prerequisites

- Node.js 20+
- pnpm

## Environment Variables

The frontend uses Cognito for authentication. Environment variables are **inlined at build time** by Vite (`import.meta.env.VITE_*`), so they must be set before running `pnpm build`.

Copy the example and fill in values from Terraform output:

```sh
cp .env.example .env
```

Or populate automatically after `terraform apply`:

```sh
echo "VITE_COGNITO_USER_POOL_ID=$(terraform -chdir=../terraform output -raw cognito_user_pool_id)" > .env
echo "VITE_COGNITO_CLIENT_ID=$(terraform -chdir=../terraform output -raw cognito_client_id)" >> .env
```

| Variable                    | Description                                     |
| --------------------------- | ----------------------------------------------- |
| `VITE_COGNITO_USER_POOL_ID` | Cognito User Pool ID (e.g., `us-east-1_AbC123`) |
| `VITE_COGNITO_CLIENT_ID`    | Cognito App Client ID (public, no secret)       |

These are public identifiers (not secrets) — safe to bake into the static bundle.

## Developing

```sh
pnpm install
pnpm dev
```

The Vite dev server proxies `/api` requests to `http://localhost:3001` (the Express API).

## Building

```sh
pnpm build
```

Output is written to `build/`. Upload to S3 for deployment.

## Deploying to S3

After building, sync the static files to the frontend S3 bucket:

```sh
aws s3 sync build/ s3://$(terraform -chdir=../terraform output -raw frontend_bucket_name) --delete
```
