# Variables
MODE ?= dev
SERVICE ?= backend
ARGS ?=
COMPOSE_DEV = docker compose -f docker/compose.development.yaml
COMPOSE_PROD = docker compose -f docker/compose.production.yaml
COMPOSE = $(if $(filter prod,$(MODE)),$(COMPOSE_PROD),$(COMPOSE_DEV))
BACKUP_DIR = backups

.PHONY: help
help:
	@echo "Docker Services:"
	@echo "  make up [MODE=dev|prod] [ARGS=...]"
	@echo "  make down [MODE=dev|prod] [ARGS=...]"
	@echo "  make build [MODE=dev|prod]"
	@echo "  make logs [SERVICE=...] [MODE=...]"
	@echo "  make restart [MODE=dev|prod]"
	@echo "  make shell [SERVICE=...] [MODE=...]"
	@echo "  make ps [MODE=dev|prod]"
	@echo ""
	@echo "Development: dev-up, dev-down, dev-build, dev-logs, dev-restart, dev-shell, dev-ps"
	@echo "Production: prod-up, prod-down, prod-build, prod-logs, prod-restart"
	@echo "Backend: backend-build, backend-install, backend-type-check, backend-dev"
	@echo "Database: db-reset, db-backup"
	@echo "Cleanup: clean, clean-all, clean-volumes"
	@echo "Utilities: status, health"

# ==================== Docker Services ====================

.PHONY: up
up:
	$(COMPOSE) up -d $(ARGS)

.PHONY: down
down:
	$(COMPOSE) down $(ARGS)

.PHONY: build
build:
	$(COMPOSE) build $(ARGS)

.PHONY: logs
logs:
	$(COMPOSE) logs -f $(SERVICE)

.PHONY: restart
restart:
	$(COMPOSE) restart $(ARGS)

.PHONY: shell
shell:
	$(COMPOSE) exec $(SERVICE) /bin/sh || $(COMPOSE) exec $(SERVICE) /bin/bash

.PHONY: ps
ps:
	$(COMPOSE) ps

# ==================== Development Aliases ====================

.PHONY: dev-up
dev-up:
	@$(MAKE) up MODE=dev ARGS="--build"

.PHONY: dev-down
dev-down:
	@$(MAKE) down MODE=dev

.PHONY: dev-build
dev-build:
	@$(MAKE) build MODE=dev

.PHONY: dev-logs
dev-logs:
	@$(MAKE) logs MODE=dev SERVICE=

.PHONY: dev-restart
dev-restart:
	@$(MAKE) restart MODE=dev

.PHONY: dev-shell
dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

.PHONY: dev-ps
dev-ps:
	@$(MAKE) ps MODE=dev

.PHONY: backend-shell
backend-shell:
	@$(MAKE) shell SERVICE=backend

.PHONY: gateway-shell
gateway-shell:
	@$(MAKE) shell SERVICE=gateway

.PHONY: mongo-shell
mongo-shell:
	$(COMPOSE_DEV) exec mongo mongosh -u $${MONGO_INITDB_ROOT_USERNAME} -p $${MONGO_INITDB_ROOT_PASSWORD}

# ==================== Production Aliases ====================

.PHONY: prod-up
prod-up:
	@$(MAKE) up MODE=prod ARGS="--build -d"

.PHONY: prod-down
prod-down:
	@$(MAKE) down MODE=prod

.PHONY: prod-build
prod-build:
	@$(MAKE) build MODE=prod

.PHONY: prod-logs
prod-logs:
	@$(MAKE) logs MODE=prod SERVICE=

.PHONY: prod-restart
prod-restart:
	@$(MAKE) restart MODE=prod

# ==================== Backend Commands ====================

.PHONY: backend-build
backend-build:
	cd backend && npm run build

.PHONY: backend-install
backend-install:
	cd backend && npm install

.PHONY: backend-type-check
backend-type-check:
	cd backend && npm run type-check

.PHONY: backend-dev
backend-dev:
	cd backend && npm run dev

# ==================== Database Commands ====================

.PHONY: db-reset
db-reset:
	@read -p "Delete all data? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_DEV) exec mongo mongosh -u $${MONGO_INITDB_ROOT_USERNAME} -p $${MONGO_INITDB_ROOT_PASSWORD} --eval "db.getSiblingDB('$${MONGO_DATABASE}').dropDatabase()"; \
	fi

.PHONY: db-backup
db-backup:
	@mkdir -p $(BACKUP_DIR)
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	docker compose -f docker/compose.development.yaml exec -T mongo mongodump \
		--username=$${MONGO_INITDB_ROOT_USERNAME} \
		--password=$${MONGO_INITDB_ROOT_PASSWORD} \
		--db=$${MONGO_DATABASE} \
		--archive > $(BACKUP_DIR)/backup_$$TIMESTAMP.archive

# ==================== Cleanup Commands ====================

.PHONY: clean
clean:
	$(COMPOSE_DEV) down 2>/dev/null || true
	$(COMPOSE_PROD) down 2>/dev/null || true

.PHONY: clean-all
clean-all:
	$(COMPOSE_DEV) down -v --rmi all 2>/dev/null || true
	$(COMPOSE_PROD) down -v --rmi all 2>/dev/null || true

.PHONY: clean-volumes
clean-volumes:
	@read -p "Delete all volumes? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_DEV) down -v 2>/dev/null || true; \
		$(COMPOSE_PROD) down -v 2>/dev/null || true; \
	fi

# ==================== Utilities ====================

.PHONY: status
status: ps

.PHONY: health
health:
	@curl -f http://localhost:5921/health 2>/dev/null && echo "Gateway: OK" || echo "Gateway: FAIL"
	@curl -f http://localhost:5921/api/health 2>/dev/null && echo "Backend: OK" || echo "Backend: FAIL"
	@$(COMPOSE) ps

# Default target
.DEFAULT_GOAL := help



# Docker Services:
#   up - Start services (use: make up [service...] or make up MODE=prod, ARGS="--build" for options)
#   down - Stop services (use: make down [service...] or make down MODE=prod, ARGS="--volumes" for options)
#   build - Build containers (use: make build [service...] or make build MODE=prod)
#   logs - View logs (use: make logs [service] or make logs SERVICE=backend, MODE=prod for production)
#   restart - Restart services (use: make restart [service...] or make restart MODE=prod)
#   shell - Open shell in container (use: make shell [service] or make shell SERVICE=gateway, MODE=prod, default: backend)
#   ps - Show running containers (use MODE=prod for production)
#
# Convenience Aliases (Development):
#   dev-up - Alias: Start development environment
#   dev-down - Alias: Stop development environment
#   dev-build - Alias: Build development containers
#   dev-logs - Alias: View development logs
#   dev-restart - Alias: Restart development services
#   dev-shell - Alias: Open shell in backend container
#   dev-ps - Alias: Show running development containers
#   backend-shell - Alias: Open shell in backend container
#   gateway-shell - Alias: Open shell in gateway container
#   mongo-shell - Open MongoDB shell
#
# Convenience Aliases (Production):
#   prod-up - Alias: Start production environment
#   prod-down - Alias: Stop production environment
#   prod-build - Alias: Build production containers
#   prod-logs - Alias: View production logs
#   prod-restart - Alias: Restart production services
#
# Backend:
#   backend-build - Build backend TypeScript
#   backend-install - Install backend dependencies
#   backend-type-check - Type check backend code
#   backend-dev - Run backend in development mode (local, not Docker)
#
# Database:
#   db-reset - Reset MongoDB database (WARNING: deletes all data)
#   db-backup - Backup MongoDB database
#
# Cleanup:
#   clean - Remove containers and networks (both dev and prod)
#   clean-all - Remove containers, networks, volumes, and images
#   clean-volumes - Remove all volumes
#
# Utilities:
#   status - Alias for ps
#   health - Check service health
#
# Help:
#   help - Display this help message