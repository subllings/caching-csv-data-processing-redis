#!/bin/bash

# Airline Data Analyzer with Redis Caching - Environment Setup Script
# This script sets up the complete environment for the project

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project info
PROJECT_NAME="Airline Data Analyzer with Redis Caching"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}║  🛫 ${PROJECT_NAME}  ║${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}║  Automated Environment Setup Script                         ║${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Python package is installed
python_package_exists() {
    python -c "import $1" >/dev/null 2>&1
}

# Step 1: Check prerequisites
print_step "1. Checking prerequisites..."

# Check Python
if command_exists python; then
    PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
    print_success "Python found: $PYTHON_VERSION"
    PYTHON_CMD="python"
elif command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    print_success "Python3 found: $PYTHON_VERSION"
    PYTHON_CMD="python3"
else
    print_error "Python not found! Please install Python 3.8+ first."
    exit 1
fi

# Check pip
if command_exists pip; then
    PIP_CMD="pip"
elif command_exists pip3; then
    PIP_CMD="pip3"
else
    print_error "pip not found! Please install pip first."
    exit 1
fi

# Check Docker
if command_exists docker; then
    print_success "Docker found: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
    DOCKER_AVAILABLE=true
else
    print_warning "Docker not found. Redis will need to be installed manually."
    DOCKER_AVAILABLE=false
fi

# Check Docker Compose
if command_exists docker-compose; then
    print_success "Docker Compose found: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
    DOCKER_COMPOSE_AVAILABLE=true
elif docker compose version >/dev/null 2>&1; then
    print_success "Docker Compose (plugin) found"
    DOCKER_COMPOSE_AVAILABLE=true
    alias docker-compose='docker compose'
else
    print_warning "Docker Compose not found."
    DOCKER_COMPOSE_AVAILABLE=false
fi

echo ""

# Step 2: Setup Python virtual environment
print_step "2. Setting up Python virtual environment..."

if [ -d "venv" ]; then
    print_warning "Virtual environment already exists. Removing old one..."
    rm -rf venv
fi

print_status "Creating virtual environment..."
$PYTHON_CMD -m venv venv

# Activate virtual environment
print_status "Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash)
    source venv/Scripts/activate
else
    # Linux/macOS
    source venv/bin/activate
fi

print_success "Virtual environment created and activated"
echo ""

# Step 3: Install Python dependencies
print_step "3. Installing Python dependencies..."

print_status "Upgrading pip..."
pip install --upgrade pip

print_status "Installing requirements..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    print_success "All Python packages installed successfully"
else
    print_error "requirements.txt not found!"
    exit 1
fi

echo ""

# Step 4: Setup Redis
print_step "4. Setting up Redis..."

if [ "$DOCKER_AVAILABLE" = true ] && [ "$DOCKER_COMPOSE_AVAILABLE" = true ]; then
    print_status "Starting Redis with Docker..."
    
    # Check if Redis is already running
    if docker-compose ps redis 2>/dev/null | grep -q "Up"; then
        print_warning "Redis container already running"
    else
        print_status "Starting Redis container..."
        docker-compose up -d redis
        
        # Wait for Redis to be ready
        print_status "Waiting for Redis to be ready..."
        sleep 3
        
        # Test Redis connection
        if docker-compose exec redis redis-cli ping >/dev/null 2>&1; then
            print_success "Redis is running and accessible"
        else
            print_warning "Redis started but connection test failed"
        fi
    fi
else
    print_warning "Docker not available. Please install Redis manually:"
    echo "  - Windows: Download from https://github.com/microsoftarchive/redis/releases"
    echo "  - macOS: brew install redis && brew services start redis"
    echo "  - Linux: sudo apt install redis-server && sudo systemctl start redis"
fi

echo ""

# Step 5: Setup project structure
print_step "5. Setting up project structure..."

# Create data directory
if [ ! -d "data" ]; then
    mkdir -p data
    print_status "Created data directory"
fi

# Create app directory if it doesn't exist
if [ ! -d "app" ]; then
    mkdir -p app
    print_status "Created app directory"
fi

print_success "Project structure ready"
echo ""

# Step 6: Test the setup
print_step "6. Testing the setup..."

print_status "Testing Python imports..."
if python -c "import redis, pandas, numpy, click, rich" >/dev/null 2>&1; then
    print_success "All Python packages imported successfully"
else
    print_error "Some Python packages failed to import"
    exit 1
fi

print_status "Testing Redis connection..."
cd app
if python -c "
import sys
sys.path.append('.')
from cache import cache
health = cache.health_check()
if health['connected']:
    print('Redis connection: OK')
    exit(0)
else:
    print('Redis connection: FAILED')
    exit(1)
" 2>/dev/null; then
    print_success "Redis connection test passed"
else
    print_warning "Redis connection test failed - Redis might not be running"
fi

cd "$PROJECT_DIR"

echo ""

# Step 7: Create activation script
print_step "7. Creating activation script..."

cat > activate-env.sh << 'EOF'
#!/bin/bash
# Activation script for the airline data analyzer project

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

echo "🛫 Airline Data Analyzer environment activated!"
echo ""
echo "Available commands:"
echo "  🚀 python app/main.py demo      - Run automated demo"
echo "  📊 python app/main.py analyze   - Interactive analysis"
echo "  🔧 python app/main.py test      - Test Redis connection"
echo "  🐳 docker-compose up -d redis   - Start Redis"
echo "  🧹 docker-compose down          - Stop Redis"
echo ""
echo "📁 Project structure:"
echo "  app/main.py      - Main application"
echo "  app/cache.py     - Redis cache helper"
echo "  data/            - CSV data files"
echo "  .env             - Configuration"
echo ""
EOF

chmod +x activate-env.sh
print_success "Created activate-env.sh script"

echo ""

# Step 8: Summary and next steps
print_step "8. Setup complete! 🎉"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    SETUP SUCCESSFUL! 🎉                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📋 QUICK START:${NC}"
echo ""
echo -e "1. ${YELLOW}Activate environment:${NC}"
echo "   source activate-env.sh"
echo ""

echo -e "2. ${YELLOW}Start Redis (if not already running):${NC}"
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "   docker-compose up -d redis"
else
    echo "   # Install and start Redis manually (see instructions above)"
fi
echo ""

echo -e "3. ${YELLOW}Run the application:${NC}"
echo "   cd app"
echo "   python main.py demo          # Quick demonstration"
echo "   python main.py analyze       # Interactive analysis"
echo "   python main.py test          # Test connection"
echo ""

echo -e "${CYAN}📊 WHAT'S INCLUDED:${NC}"
echo "✅ Python virtual environment with all dependencies"
echo "✅ Redis caching system"
echo "✅ Sample airline dataset (auto-generated)"
echo "✅ Interactive CLI interface"
echo "✅ Performance benchmarking"
echo "✅ Comprehensive logging"
echo ""

echo -e "${CYAN}🔗 USEFUL LINKS:${NC}"
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "• Redis Commander (Web UI): http://localhost:8081 (run with --profile gui)"
fi
echo "• Project README: README.md"
echo "• Redis Setup Guide: REDIS_SETUP.md"
echo ""

echo -e "${CYAN}🆘 TROUBLESHOOTING:${NC}"
echo "• If Redis connection fails: docker-compose restart redis"
echo "• If Python imports fail: source activate-env.sh"
echo "• For detailed logs: Check docker-compose logs redis"
echo ""

echo -e "${BLUE}Happy coding! 🚀${NC}"
echo ""

# Save environment info
cat > .env-info << EOF
# Environment setup information
SETUP_DATE=$(date)
PYTHON_VERSION=$PYTHON_VERSION
PYTHON_CMD=$PYTHON_CMD
PIP_CMD=$PIP_CMD
DOCKER_AVAILABLE=$DOCKER_AVAILABLE
DOCKER_COMPOSE_AVAILABLE=$DOCKER_COMPOSE_AVAILABLE
PROJECT_DIR=$PROJECT_DIR
EOF

print_success "Environment info saved to .env-info"
