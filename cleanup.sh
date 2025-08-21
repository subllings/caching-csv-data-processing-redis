#!/bin/bash
# Cleanup script for the airline data analyzer project

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 Airline Data Analyzer - Cleanup Script${NC}"
echo ""

# Function to ask for confirmation
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Stop Docker containers
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose ps | grep -q "Up"; then
        if confirm "Stop Docker containers?"; then
            echo -e "${BLUE}[INFO]${NC} Stopping Docker containers..."
            docker-compose down
            echo -e "${GREEN}[SUCCESS]${NC} Docker containers stopped"
        fi
    fi
fi

# Remove virtual environment
if [ -d "venv" ]; then
    if confirm "Remove virtual environment?"; then
        echo -e "${BLUE}[INFO]${NC} Removing virtual environment..."
        rm -rf venv
        echo -e "${GREEN}[SUCCESS]${NC} Virtual environment removed"
    fi
fi

# Clean cache files
if confirm "Remove Python cache files (__pycache__, *.pyc)?"; then
    echo -e "${BLUE}[INFO]${NC} Cleaning Python cache files..."
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    echo -e "${GREEN}[SUCCESS]${NC} Python cache files cleaned"
fi

# Remove generated data
if [ -d "data" ] && [ -f "data/flights.csv" ]; then
    if confirm "Remove generated sample data?"; then
        echo -e "${BLUE}[INFO]${NC} Removing sample data..."
        rm -f data/flights.csv
        rm -f data/test_flights.csv
        echo -e "${GREEN}[SUCCESS]${NC} Sample data removed"
    fi
fi

# Remove environment info
if [ -f ".env-info" ]; then
    if confirm "Remove environment info file?"; then
        rm -f .env-info
        echo -e "${GREEN}[SUCCESS]${NC} Environment info removed"
    fi
fi

# Remove logs
if [ -d "logs" ]; then
    if confirm "Remove log files?"; then
        rm -rf logs
        echo -e "${GREEN}[SUCCESS]${NC} Log files removed"
    fi
fi

# Remove Docker volumes (optional)
if command -v docker >/dev/null 2>&1; then
    if docker volume ls | grep -q "caching-csv-data-processing-redis"; then
        if confirm "Remove Docker volumes (this will delete Redis data)?"; then
            echo -e "${BLUE}[INFO]${NC} Removing Docker volumes..."
            docker-compose down -v 2>/dev/null || true
            echo -e "${GREEN}[SUCCESS]${NC} Docker volumes removed"
        fi
    fi
fi

echo ""
echo -e "${GREEN}🎉 Cleanup completed!${NC}"
echo ""
echo -e "${BLUE}To setup the environment again, run:${NC}"
echo "  bash setup-env.sh"
echo ""
