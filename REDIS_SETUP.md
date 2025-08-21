# Redis Setup Instructions

## Option 1: Using Docker (Recommended)

### Start Redis
```bash
docker-compose up -d redis
```

### Start Redis with Web UI
```bash
docker-compose --profile gui up -d
```
- Redis will be available at `localhost:6379`
- Redis Commander (Web UI) will be available at `http://localhost:8081`

### Stop Redis
```bash
docker-compose down
```

## Option 2: Local Redis Installation

### Windows
1. Download Redis from: https://github.com/microsoftarchive/redis/releases
2. Extract and run `redis-server.exe`

### macOS
```bash
brew install redis
brew services start redis
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

## Setup Python Environment

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Test Redis connection:
```bash
cd app
python cache.py
```

## Configuration

Edit `.env` file to configure Redis connection:
```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=
CACHE_TTL=60
```

## Verify Connection

Run the test script to verify everything works:
```bash
cd app
python cache.py
```

You should see:
```
🔧 Testing Redis connection...
✅ Connected to Redis at localhost:6379
💾 Cached key: test:connection (TTL: 10s)
🎯 Cache HIT for key: test:connection
Retrieved: {'message': 'Hello Redis!', 'timestamp': '2025-08-21'}
🗑️ Deleted key: test:connection
✅ Redis connection test completed successfully!
```
