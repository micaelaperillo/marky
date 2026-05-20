.PHONY: build plan deploy deploy-frontend deploy-all destroy

build:
	@if [ -d lambdas ]; then cd lambdas && pnpm install && pnpm -r build; \
	else echo "lambdas/ not found, skipping build"; fi

plan: build
	cd terraform && terraform plan

deploy: build
	cd terraform && terraform apply
	@echo ""
	@echo "Run 'make deploy-frontend' to build and upload the frontend."

deploy-frontend:
	@cd terraform && \
	POOL_ID=$$(terraform output -raw cognito_user_pool_id) || { echo "Failed to get cognito_user_pool_id"; exit 1; } && \
	CLIENT_ID=$$(terraform output -raw cognito_client_id) || { echo "Failed to get cognito_client_id"; exit 1; } && \
	BUCKET=$$(terraform output -raw frontend_bucket_name) || { echo "Failed to get frontend_bucket_name"; exit 1; } && \
	API_URL=$$(terraform output -raw api_url) || { echo "Failed to get api_url"; exit 1; } && \
	cd ../frontend && \
	pnpm install && \
	VITE_API_BASE_URL=$$API_URL/api \
	VITE_COGNITO_USER_POOL_ID=$$POOL_ID \
	VITE_COGNITO_CLIENT_ID=$$CLIENT_ID \
	BASE_PATH=/prod \
	pnpm build && \
	aws s3 sync build/ s3://$$BUCKET/ --delete

deploy-all: deploy deploy-frontend

destroy:
	cd terraform && terraform destroy
