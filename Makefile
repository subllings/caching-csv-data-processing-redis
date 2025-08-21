# Airline Data Analyzer with Redis Caching - Makefile
# Simple commands to manage the project

.PHONY: help setup activate clean demo analyze test docker-up docker-down docker-logs install

# Default target
help:
	@echo "Airline Data Analyzer with Redis Caching"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup        - Setup the complete environment"
	@echo "  make activate     - Activate the virtual environment"
	@echo "  make install      - Install Python dependencies"
	@echo "  make docker-up    - Start Redis with Docker"
	@echo "  make docker-down  - Stop Redis containers"
	@echo "  make docker-logs  - Show Redis logs"
	@echo "  make test         - Test Redis connection"
	@echo "  make demo         - Run automated demo"
	@echo "  make analyze      - Run interactive analysis"
	@echo "  make clean        - Clean up everything"
	@echo ""

# Setup complete environment
setup:
	@echo "Setting up environment..."
	@bash setup-env.sh

# Activate virtual environment
activate:
	@echo "Activating environment..."
	@bash activate-env.sh

# Install dependencies only
install:
	@echo "Installing dependencies..."
	@pip install -r requirements.txt

# Docker commands
docker-up:
	@echo "Starting Redis..."
	@docker-compose up -d redis
	@echo "Redis started on localhost:6379"

docker-down:
	@echo "Stopping Redis..."
	@docker-compose down

docker-logs:
	@echo "Redis logs:"
	@docker-compose logs redis

# Application commands
test:
	@echo "Testing Redis connection..."
	@cd app && python main.py test

demo:
	@echo "Running demo..."
	@cd app && python main.py demo

analyze:
	@echo "Starting interactive analysis..."
	@cd app && python main.py analyze

# Cleanup
clean:
	@echo "Cleaning up..."
	@bash cleanup.sh

# Development commands
dev-setup: setup docker-up
	@echo "Development environment ready!"
	@echo "Run 'make demo' to test everything"

# Quick test after setup
verify: docker-up test demo
	@echo "Everything is working!"
