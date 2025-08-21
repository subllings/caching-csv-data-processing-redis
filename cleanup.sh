#!/bin/bash

# ==========================================================
# CLEANUP SCRIPT
# Usage: ./cleanup.sh
# ==========================================================

clear

# === Define color codes ===
BLUE_BG="\033[44m"
GREEN_BG="\033[42m"
RED_BG="\033[41m"
YELLOW_BG="\033[43m"
WHITE_TEXT="\033[97m"
BLACK_TEXT="\033[30m"
RESET="\033[0m"

# === Define print helpers ===
print_blue() {
    echo ""
    echo -e "${BLUE_BG}${WHITE_TEXT}>>> $1${RESET}"
    echo ""
}

print_green() {
    echo ""
    echo -e "${GREEN_BG}${BLACK_TEXT}>>> $1${RESET}"
    echo ""
}

print_yellow() {
    echo ""
    echo -e "${YELLOW_BG}${BLACK_TEXT}>>> WARNING: $1${RESET}"
    echo ""
}

print_error() {
    echo ""
    echo -e "${RED_BG}${WHITE_TEXT}>>> ERROR: $1${RESET}"
    echo ""
}

# === Confirmation ===
print_yellow "This will completely clean up the project environment:"
echo "  - Stop and remove Redis containers"
echo "  - Remove Python virtual environment (.venv)"
echo "  - Remove cache files (__pycache__, .pytest_cache)"
echo "  - Remove VS Code settings (.vscode)"
echo "  - Remove Jupyter kernel registration"
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_blue "Cleanup cancelled."
    exit 0
fi

# === Stop and remove Docker containers ===
print_blue "Stopping and removing Redis containers..."
docker-compose down --volumes --remove-orphans 2>/dev/null || echo "No containers to stop"

# === Remove Docker images (optional) ===
print_blue "Removing Redis Docker images..."
docker image rm redis:7-alpine rediscommander/redis-commander:latest 2>/dev/null || echo "Images already removed or not found"

# === Remove virtual environment ===
if [ -d ".venv" ]; then
    print_blue "Removing Python virtual environment (.venv)..."
    rm -rf .venv
else
    echo "Virtual environment not found (already clean)"
fi

# === Remove cache directories ===
print_blue "Removing Python cache files..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true

# === Remove VS Code settings ===
if [ -d ".vscode" ]; then
    print_blue "Removing VS Code settings (.vscode)..."
    rm -rf .vscode
else
    echo "VS Code settings not found (already clean)"
fi

# === Remove Jupyter kernel ===
print_blue "Removing Jupyter kernel registration..."
jupyter kernelspec uninstall venv -f 2>/dev/null || echo "Jupyter kernel not found (already clean)"

# === Remove log files (if any) ===
print_blue "Removing log files..."
find . -name "*.log" -delete 2>/dev/null || true
find . -type d -name "logs" -exec rm -rf {} + 2>/dev/null || true

# === Clean Docker system (optional) ===
print_blue "Cleaning Docker system (unused containers, networks, images)..."
docker system prune -f 2>/dev/null || echo "Docker cleanup skipped"

# === Show what remains ===
print_blue "Cleanup completed! Remaining files:"
ls -la

print_green "Environment completely cleaned!"
echo ""
echo "To rebuild the environment, run: ./setup-env.sh"
echo ""
