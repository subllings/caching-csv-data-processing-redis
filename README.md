# 🛫 Airline Data Analyzer with Redis Caching

A Python application that demonstrates **Redis caching** for optimizing expensive data transformations on airline delay datasets.

![Python](https://img.shields.io/badge/python-v3.8+-blue.svg)
![Redis](https://img.shields.io/badge/redis-v7.0+-red.svg)
![Pandas](https://img.shields.io/badge/pandas-v2.1+-green.svg)

## 🎯 Overview

This project processes airline delay data and demonstrates how **Redis caching** can dramatically improve performance for repeated queries. It includes:

- **CSV data processing** with pandas
- **Redis caching** with configurable TTL
- **Performance benchmarking** (cache vs CSV)
- **Beautiful CLI interface** with Rich
- **Comprehensive airline analytics**

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
```bash
# Setup everything automatically
bash setup-env.sh

# Activate environment
source activate-env.sh

# Run demo
cd app && python main.py demo
```

### Option 2: Using Make
```bash
# Setup and start everything
make setup
make docker-up

# Run demo
make demo

# Interactive analysis
make analyze
```

### Option 3: Manual Setup
```bash
# 1. Start Redis
docker-compose up -d redis

# 2. Install Dependencies
pip install -r requirements.txt

# 3. Run the Application
cd app
python main.py analyze

# 4. Quick Demo
python main.py demo
```

## �️ Available Scripts

### Setup & Management
```bash
bash setup-env.sh          # Complete environment setup
source activate-env.sh      # Activate virtual environment  
bash cleanup.sh             # Clean up everything
```

### Make Commands
```bash
make setup                  # Setup complete environment
make docker-up              # Start Redis
make demo                   # Run automated demo
make analyze                # Interactive analysis
make test                   # Test Redis connection
make clean                  # Clean up everything
```

### Docker Management
```bash
docker-compose up -d redis              # Start Redis
docker-compose --profile gui up -d      # Start with Web UI
docker-compose down                      # Stop everything
docker-compose logs redis               # View Redis logs
```

## �📊 Features

### Core Analytics
- **Average delay per airline** (arrival/departure)
- **Total flights per airport** (origin/destination)
- **Monthly delay statistics**
- **Comprehensive airline performance metrics**

### Caching Features
- ✅ **Redis caching** with configurable TTL
- ✅ **Cache hit/miss tracking**
- ✅ **Performance comparison**
- ✅ **Cache invalidation**
- ✅ **Structured data storage** (JSON serialization)

### Nice-to-Have Features
- ✅ **Multiple query types**
- ✅ **Redis health monitoring**
- ✅ **Cache statistics dashboard**
- ✅ **Docker support**
- ✅ **Beautiful CLI interface**
- ✅ **Comprehensive logging**

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CSV Dataset   │    │   Redis Cache   │    │  CLI Interface  │
│                 │    │                 │    │                 │
│ • Flight data   │◄──►│ • Cached results│◄──►│ • Interactive   │
│ • 100k+ rows    │    │ • TTL: 60s      │    │ • Performance   │
│ • Multiple cols │    │ • JSON format   │    │ • Statistics    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
caching-csv-data-processing-redis/
├── app/
│   ├── main.py              # Main application with CLI
│   └── cache.py             # Redis connection helper
├── data/
│   └── flights.csv          # Dataset (auto-generated if missing)
├── Statement/
│   └── 03-large-csv-caching-exercice.md
├── docker-compose.yml       # Redis setup
├── requirements.txt         # Python dependencies
├── .env                     # Configuration
├── REDIS_SETUP.md          # Redis installation guide
└── README.md               # This file
```

## 🔧 Configuration

Edit `.env` file to customize settings:

```env
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=

# Cache Configuration
CACHE_TTL=60                 # Time-to-live in seconds

# Dataset Configuration
CSV_FILE_PATH=data/flights.csv
```

## 🎮 Usage Examples

### Interactive Analysis
```bash
cd app
python main.py analyze
```

### Automated Demo
```bash
cd app
python main.py demo
```

### Test Redis Connection
```bash
cd app
python main.py test
```

## 📈 Performance Results

Here's what you can expect to see:

### First Run (Computing from CSV)
```
📊 Computing from CSV data...
💾 Result cached in Redis
⏱️  Execution time: 1.234 seconds
```

### Second Run (Retrieved from Cache)
```
🎯 Retrieved from Redis cache
⏱️  Execution time: 0.003 seconds
🚀 Speedup: 411x faster!
```

### Performance Comparison Table
```
┏━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━━━━┓
┃ Query Type          ┃ CSV Time (avg)  ┃ Cache Time (avg) ┃ Speedup   ┃ Cache Hits  ┃
┡━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━━━━┩
│ avg_delay_airline   │ 1.234s          │ 0.003s           │ 411.3x    │ 5           │
│ flights_airport     │ 0.567s          │ 0.002s           │ 283.5x    │ 3           │
│ airline_performance │ 2.345s          │ 0.004s           │ 586.3x    │ 2           │
└─────────────────────┴─────────────────┴──────────────────┴───────────┴─────────────┘
```

### Redis Statistics
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                              Redis Statistics                               ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ Total Keys: 12                                                              │
│ Cache Hits: 23,456                                                          │
│ Cache Misses: 1,234                                                         │
│ Hit Rate: 95.0%                                                             │
│ Memory Usage: 2.1MB                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🗂️ Dataset

The application uses airline delay data with the following structure:

| Column      | Description                    | Example     |
|-------------|--------------------------------|-------------|
| FL_DATE     | Flight date                    | 2024-01-15  |
| OP_CARRIER  | Airline code                   | AA, DL, UA  |
| ORIGIN      | Origin airport                 | ATL, LAX    |
| DEST        | Destination airport            | ORD, DFW    |
| DEP_DELAY   | Departure delay (minutes)      | 15.5        |
| ARR_DELAY   | Arrival delay (minutes)        | 12.3        |
| DISTANCE    | Flight distance (miles)        | 1247        |
| AIR_TIME    | Flight duration (minutes)      | 145         |

**Note:** If no dataset is provided, the application automatically generates 100,000 sample flights for demonstration.

## 🐳 Docker Setup

### Start Redis Only
```bash
docker-compose up -d redis
```

### Start with Redis Web UI
```bash
docker-compose --profile gui up -d
```
- Redis: `localhost:6379`
- Redis Commander (Web UI): `http://localhost:8081`

### Stop Services
```bash
docker-compose down
```

## 🔍 Sample Output

### Average Delay Analysis
```
┏━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Airline  ┃                      Average Arrival Delay (minutes)                ┃
┡━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ AA       │ 12.45                                                                │
│ DL       │ 8.92                                                                 │
│ UA       │ 15.67                                                                │
│ WN       │ 11.23                                                                │
│ AS       │ 9.78                                                                 │
└──────────┴──────────────────────────────────────────────────────────────────────┘
```

### Airport Traffic Analysis
```
┏━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Airport      ┃                    Total Flights per Origin Airport              ┃
┡━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ ATL          │ 8,234                                                            │
│ LAX          │ 7,456                                                            │
│ ORD          │ 6,789                                                            │
│ DFW          │ 6,123                                                            │
│ DEN          │ 5,567                                                            │
└──────────────┴──────────────────────────────────────────────────────────────────┘
```

## 🧪 Testing

### Test Redis Connection
```bash
cd app
python cache.py
```

### Run Analysis Demo
```bash
cd app
python main.py demo
```

### Manual Testing
```bash
cd app
python main.py analyze
# Select option 1, then run it again to see caching in action
```

## 🚨 Troubleshooting

### Redis Connection Issues
```bash
# Check if Redis is running
docker-compose ps

# View Redis logs
docker-compose logs redis

# Test connection manually
redis-cli ping
```

### Data Loading Issues
- The app automatically generates sample data if CSV is missing
- Check file permissions in the `data/` directory
- Verify CSV format matches expected columns

### Performance Issues
- Increase cache TTL in `.env` for longer cache retention
- Monitor Redis memory usage with `docker stats`
- Use smaller dataset for testing

## 🔧 Advanced Configuration

### Custom Dataset
Place your airline dataset in `data/flights.csv` with required columns:
- `OP_CARRIER`, `ORIGIN`, `DEST`, `ARR_DELAY`, `DEP_DELAY`

### Redis Optimization
```env
# Increase TTL for longer cache retention
CACHE_TTL=300

# Use different Redis database
REDIS_DB=1
```

### Production Setup
- Use Redis Cluster for high availability
- Implement connection pooling
- Add Redis authentication
- Monitor cache hit rates

## 📊 Cache Strategy

### Key Generation
```python
cache_key = f"airline_data:{query_type}:{param1}:{param2}"
# Example: "airline_data:avg_delay_airline:ARR_DELAY"
```

### TTL Policy
- Default: 60 seconds
- Configurable via environment variables
- Automatic expiration and refresh

### Data Serialization
- JSON format for cross-platform compatibility
- Handles datetime objects automatically
- Preserves data types

## 🎯 Learning Outcomes

After completing this project, you'll understand:

- ✅ **Redis caching patterns** and best practices
- ✅ **Performance optimization** with caching layers
- ✅ **TTL strategies** for data freshness
- ✅ **Cache invalidation** techniques
- ✅ **Monitoring and metrics** for cache performance
- ✅ **Real-world data processing** with pandas

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is part of the BeCode Data Engineering curriculum.

---

**Happy Caching! 🚀**
