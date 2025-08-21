#!/usr/bin/env python3
"""
Test script to validate the complete airline data analyzer setup
"""

import sys
import os
import time
import subprocess

# Add app directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from cache import cache
from main import AirlineDataAnalyzer

def test_redis_connection():
    """Test Redis connection"""
    print("🔧 Testing Redis connection...")
    
    health = cache.health_check()
    if health['connected']:
        print(f"✅ Redis connected (latency: {health['latency_ms']}ms)")
        return True
    else:
        print(f"❌ Redis connection failed: {health['error']}")
        return False

def test_sample_data_generation():
    """Test sample data generation"""
    print("📊 Testing sample data generation...")
    
    analyzer = AirlineDataAnalyzer('data/test_flights.csv')
    success = analyzer.load_data()
    
    if success and analyzer.data is not None:
        print(f"✅ Sample data generated: {len(analyzer.data):,} rows")
        return True
    else:
        print("❌ Failed to generate sample data")
        return False

def test_caching_functionality():
    """Test caching functionality"""
    print("🎯 Testing caching functionality...")
    
    analyzer = AirlineDataAnalyzer('data/test_flights.csv')
    analyzer.load_data()
    
    # Clear cache to start fresh
    analyzer.clear_cache()
    
    # First query (should be slow)
    start_time = time.time()
    result1 = analyzer.get_average_delay_per_airline('ARR_DELAY')
    first_time = time.time() - start_time
    
    # Second query (should be fast from cache)
    start_time = time.time()
    result2 = analyzer.get_average_delay_per_airline('ARR_DELAY')
    second_time = time.time() - start_time
    
    if result1 == result2 and second_time < first_time:
        speedup = first_time / second_time if second_time > 0 else 0
        print(f"✅ Caching works! Speedup: {speedup:.1f}x")
        print(f"   First run: {first_time:.3f}s")
        print(f"   Second run: {second_time:.3f}s")
        return True
    else:
        print("❌ Caching test failed")
        return False

def test_all_query_types():
    """Test all query types"""
    print("📈 Testing all query types...")
    
    analyzer = AirlineDataAnalyzer('data/test_flights.csv')
    analyzer.load_data()
    
    tests = [
        ('Average Arrival Delay', lambda: analyzer.get_average_delay_per_airline('ARR_DELAY')),
        ('Average Departure Delay', lambda: analyzer.get_average_delay_per_airline('DEP_DELAY')),
        ('Flights per Origin', lambda: analyzer.get_flights_per_airport('ORIGIN')),
        ('Flights per Destination', lambda: analyzer.get_flights_per_airport('DEST')),
        ('Monthly Stats', lambda: analyzer.get_delay_stats_by_month()),
        ('Airline Performance', lambda: analyzer.get_airline_performance_summary()),
    ]
    
    passed = 0
    for test_name, test_func in tests:
        try:
            result = test_func()
            if result:
                print(f"  ✅ {test_name}")
                passed += 1
            else:
                print(f"  ❌ {test_name} (no data)")
        except Exception as e:
            print(f"  ❌ {test_name} (error: {e})")
    
    if passed == len(tests):
        print(f"✅ All {passed} query types working!")
        return True
    else:
        print(f"❌ {len(tests) - passed} query types failed")
        return False

def test_docker_redis():
    """Test if Docker Redis is running"""
    print("🐳 Testing Docker Redis setup...")
    
    try:
        result = subprocess.run(['docker-compose', 'ps'], 
                              capture_output=True, text=True, timeout=10)
        
        if 'redis' in result.stdout and 'Up' in result.stdout:
            print("✅ Docker Redis is running")
            return True
        else:
            print("⚠️ Docker Redis not detected, trying to start...")
            
            # Try to start Redis
            start_result = subprocess.run(['docker-compose', 'up', '-d', 'redis'], 
                                        capture_output=True, text=True, timeout=30)
            
            if start_result.returncode == 0:
                print("✅ Redis started successfully")
                time.sleep(2)  # Wait for Redis to be ready
                return True
            else:
                print(f"❌ Failed to start Redis: {start_result.stderr}")
                return False
                
    except subprocess.TimeoutExpired:
        print("⏰ Docker command timed out")
        return False
    except FileNotFoundError:
        print("⚠️ Docker/docker-compose not found")
        return False
    except Exception as e:
        print(f"❌ Docker test failed: {e}")
        return False

def run_all_tests():
    """Run all tests"""
    print("🧪 Running comprehensive test suite...\n")
    
    tests = [
        ("Docker Redis Setup", test_docker_redis),
        ("Redis Connection", test_redis_connection),
        ("Sample Data Generation", test_sample_data_generation),
        ("Caching Functionality", test_caching_functionality),
        ("All Query Types", test_all_query_types),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n{'='*50}")
        print(f"🔍 Running: {test_name}")
        print(f"{'='*50}")
        
        try:
            if test_func():
                passed += 1
            time.sleep(1)  # Brief pause between tests
        except Exception as e:
            print(f"❌ Test '{test_name}' failed with error: {e}")
    
    # Summary
    print(f"\n{'='*50}")
    print(f"📊 TEST SUMMARY")
    print(f"{'='*50}")
    print(f"Passed: {passed}/{total}")
    print(f"Success Rate: {(passed/total)*100:.1f}%")
    
    if passed == total:
        print("🎉 All tests passed! Your setup is ready!")
        print("\n🚀 You can now run:")
        print("   cd app && python main.py demo")
        print("   cd app && python main.py analyze")
    else:
        print(f"⚠️ {total - passed} tests failed. Please check the errors above.")
        
        # Provide troubleshooting hints
        print("\n🔧 Troubleshooting hints:")
        print("1. Make sure Docker is running: docker --version")
        print("2. Start Redis manually: docker-compose up -d redis")
        print("3. Check Redis: docker-compose ps")
        print("4. Install dependencies: pip install -r requirements.txt")
    
    return passed == total

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
