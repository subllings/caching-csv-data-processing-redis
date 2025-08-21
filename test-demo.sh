#!/bin/bash

# ==========================================================
# TEST & DEMO SCRIPT
# USAGE:
# cd /e/_SoftEng/_BeCode/caching-csv-data-processing-redis
# chmod +x test-demo.sh
# ./test-demo.sh
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
    echo -e "${YELLOW_BG}${BLACK_TEXT}>>> $1${RESET}"
    echo ""
}

print_error() {
    echo ""
    echo -e "${RED_BG}${WHITE_TEXT}>>> ERROR: $1${RESET}"
    echo ""
    exit 1
}

# === Check if we're in the right directory ===
if [ ! -f "app/main.py" ]; then
    print_error "app/main.py not found. Are you in the project directory?"
fi

# === Check if virtual environment exists ===
if [ ! -d ".venv" ]; then
    print_error "Virtual environment not found. Run ./setup-env.sh first"
fi

# === Activate virtual environment ===
print_blue "Activating virtual environment..."
source .venv/Scripts/activate || print_error "Failed to activate virtual environment"

# === Check Python version ===
print_blue "Python environment:"
python --version
which python

# === Check if Redis is running ===
print_blue "Checking Redis connection..."
if ! docker exec redis-cache redis-cli ping &> /dev/null; then
    print_yellow "Redis is not running. Starting Redis..."
    docker-compose up -d redis
    
    # Wait for Redis to be ready
    for i in {1..15}; do
        if docker exec redis-cache redis-cli ping &> /dev/null; then
            print_green "Redis is ready!"
            break
        else
            echo "Waiting for Redis... ($i/15)"
            sleep 1
        fi
        
        if [ $i -eq 15 ]; then
            print_error "Redis failed to start. Please check Docker"
        fi
    done
else
    print_green "Redis is already running!"
fi

# === Test Redis connection from Python ===
print_blue "Testing Redis connection from Python..."
python app/main.py test

if [ $? -ne 0 ]; then
    print_error "Redis connection test failed"
fi

print_green "Redis connection test passed!"

# === Ask user what to run ===
echo ""
echo "What would you like to run?"
echo "1. Quick demo (automated cache performance)"
echo "2. Interactive analysis (manual menu)"
echo "3. Both (demo first, then interactive)"
echo "4. Exit"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        print_blue "Running automated demo..."
        python app/main.py demo
        ;;
    2)
        print_blue "Starting interactive analysis..."
        echo "Tip: Try option 1 twice to see cache in action!"
        python app/main.py analyze
        ;;
    3)
        print_blue "Running automated demo first..."
        python app/main.py demo
        
        echo ""
        echo "Press Enter to continue to interactive analysis..."
        read
        
        print_blue "Starting interactive analysis..."
        echo "Tip: Try option 1 twice to see cache in action!"
        python app/main.py analyze
        ;;
    4)
        print_green "Goodbye!"
        exit 0
        ;;
    *)
        print_error "Invalid choice. Please run the script again."
        ;;
esac

print_green "Demo completed!"
echo ""
echo "Available commands:"
echo "  python app/main.py test     # Test Redis connection"
echo "  python app/main.py demo     # Automated demo"
echo "  python app/main.py analyze  # Interactive analysis"
echo "  docker-compose logs redis   # View Redis logs"
echo "  docker-compose down         # Stop Redis"
echo ""
