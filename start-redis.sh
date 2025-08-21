#!/bin/bash

# ==========================================================
# REDIS STARTUP SCRIPT
# USAGE:
# cd /e/_SoftEng/_BeCode/caching-csv-data-processing-redis
# chmod +x start-redis.sh
# ./start-redis.sh
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

# === Check if Docker is installed ===
print_blue "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
fi

# === Check if Docker is running ===
print_blue "Checking if Docker is running..."
if ! docker info &> /dev/null; then
    print_yellow "Docker is not running. Please start Docker Desktop and wait for it to initialize."
    echo "Then run this script again."
    exit 1
fi

print_green "Docker is running!"

# === Check if docker-compose.yml exists ===
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Are you in the project directory?"
fi

# === Stop existing containers (if any) ===
print_blue "Stopping any existing Redis containers..."
docker-compose down 2>/dev/null || echo "No containers to stop"

# === Start Redis container ===
print_blue "Starting Redis container..."
docker-compose up -d redis

# === Wait for Redis to be ready ===
print_blue "Waiting for Redis to be ready..."
for i in {1..30}; do
    if docker exec redis-cache redis-cli ping &> /dev/null; then
        print_green "Redis is ready!"
        break
    else
        echo "Waiting... ($i/30)"
        sleep 1
    fi
    
    if [ $i -eq 30 ]; then
        print_error "Redis failed to start after 30 seconds"
    fi
done

# === Show Redis status ===
print_blue "Redis container status:"
docker-compose ps

# === Test Redis connection ===
print_blue "Testing Redis connection..."
REDIS_RESPONSE=$(docker exec redis-cache redis-cli ping 2>/dev/null)
if [ "$REDIS_RESPONSE" = "PONG" ]; then
    print_green "Redis connection test: SUCCESS"
else
    print_error "Redis connection test: FAILED"
fi

# === Show Redis info ===
print_blue "Redis server information:"
docker exec redis-cache redis-cli info server | grep "redis_version\|uptime_in_seconds\|tcp_port"

# === Show connection details ===
print_green "Redis is running and ready!"
echo ""
echo "Connection details:"
echo "  Host: localhost"
echo "  Port: 6379"
echo "  URL: redis://localhost:6379"
echo ""
echo "Available commands:"
echo "  docker-compose logs redis     # View Redis logs"
echo "  docker exec -it redis-cache redis-cli  # Redis CLI"
echo "  python app/main.py test       # Test Python connection"
echo "  docker-compose down           # Stop Redis"
echo ""

# === Optional: Start with Web UI ===
echo "Do you want to start Redis with Web UI? (y/N):"
read -p "> " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_blue "Starting Redis with Web UI..."
    docker-compose --profile gui up -d
    
    print_green "Redis Web UI started!"
    echo ""
    echo "Access Redis Commander at: http://localhost:8081"
    echo ""
fi

print_green "Redis setup complete!"
