# Homelab Stack - Makefile
# Quick commands for managing the stack

.PHONY: help start stop restart rebuild status logs clean purge-cache nginx-reload

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Homelab Stack - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

start: ## Start all services
	@./scripts/homelab.sh start

stop: ## Stop all services
	@./scripts/homelab.sh stop

restart: ## Restart all services
	@./scripts/homelab.sh restart

rebuild: ## Rebuild all services from scratch
	@./scripts/homelab.sh rebuild

status: ## Show services status
	@./scripts/homelab.sh status

logs: ## Show logs (use 'make logs SERVICE=nginx' for specific service)
	@./scripts/homelab.sh logs $(SERVICE)

clean: ## Stop and remove all containers, networks, volumes
	@docker compose down -v
	@echo "✓ All containers, networks, and volumes removed"

# PHP version shortcuts
php72: ## Access PHP 7.2 container
	@docker compose exec php72 bash

php74: ## Access PHP 7.4 container
	@docker compose exec php74 bash

php80: ## Access PHP 8.0 container
	@docker compose exec php80 bash

php81: ## Access PHP 8.1 container
	@docker compose exec php81 bash

php82: ## Access PHP 8.2 container
	@docker compose exec php82 bash

php83: ## Access PHP 8.3 container
	@docker compose exec php83 bash

php84: ## Access PHP 8.4 container (default)
	@docker compose exec php84 bash

# Quick setup
setup: ## Initial setup (copy .env, create directories)
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ .env file created"; \
	fi
	@mkdir -p projects/default/public
	@if [ ! -f projects/default/public/index.php ]; then \
		echo "<?php phpinfo();" > projects/default/public/index.php; \
		echo "✓ Default project created"; \
	fi
	@mkdir -p xdebug-output
	@echo "✓ Setup complete. Run 'make start' to start the stack."

# Development helpers
composer-install: ## Run composer install in PHP 8.4
	@docker compose exec php84 composer install

composer-update: ## Run composer update in PHP 8.4
	@docker compose exec php84 composer update

npm-install: ## Run npm install in PHP 8.4
	@docker compose exec php84 npm install

npm-build: ## Run npm build in PHP 8.4
	@docker compose exec php84 npm run build
