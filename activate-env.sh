#!/bin/bash
# Simple activation script for the airline data analyzer project

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash)
    if [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        echo -e "${YELLOW}⚠️ Virtual environment not found. Run setup-env.sh first.${NC}"
        exit 1
    fi
else
    # Linux/macOS
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        echo -e "${YELLOW}⚠️ Virtual environment not found. Run setup-env.sh first.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}🛫 Airline Data Analyzer environment activated!${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo "  🚀 python app/main.py demo      - Run automated demo"
echo "  📊 python app/main.py analyze   - Interactive analysis"  
echo "  🔧 python app/main.py test      - Test Redis connection"
echo "  🐳 docker-compose up -d redis   - Start Redis"
echo "  🧹 docker-compose down          - Stop Redis"
echo ""
echo -e "${BLUE}Quick start:${NC}"
echo "  cd app && python main.py demo"
echo ""
