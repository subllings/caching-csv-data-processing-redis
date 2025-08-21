import redis
import json
import logging
import os
from typing import Optional, Any
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class RedisCache:
    """Redis cache helper class for managing cache operations"""
    
    def __init__(self):
        """Initialize Redis connection with configuration from environment variables"""
        # Set up logging first
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        self.host = os.getenv('REDIS_HOST', 'localhost')
        self.port = int(os.getenv('REDIS_PORT', 6379))
        self.db = int(os.getenv('REDIS_DB', 0))
        self.password = os.getenv('REDIS_PASSWORD', None)
        self.ttl = int(os.getenv('CACHE_TTL', 60))
        
        # Initialize Redis client
        self.redis_client = None
        self.connect()
    
    def connect(self) -> bool:
        """Establish connection to Redis server"""
        try:
            self.redis_client = redis.Redis(
                host=self.host,
                port=self.port,
                db=self.db,
                password=self.password if self.password else None,
                decode_responses=True,  # Automatically decode responses to strings
                socket_connect_timeout=5,
                socket_timeout=5
            )
            
            # Test the connection
            self.redis_client.ping()
            self.logger.info(f"Connected to Redis at {self.host}:{self.port}")
            return True
            
        except redis.ConnectionError as e:
            self.logger.error(f"Failed to connect to Redis: {e}")
            self.redis_client = None
            return False
        except Exception as e:
            self.logger.error(f"Unexpected error connecting to Redis: {e}")
            self.redis_client = None
            return False
    
    def is_connected(self) -> bool:
        """Check if Redis is connected and accessible"""
        if not self.redis_client:
            return False
        try:
            self.redis_client.ping()
            return True
        except:
            return False
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        if not self.is_connected():
            self.logger.warning("Redis not connected, cannot retrieve from cache")
            return None
        
        try:
            value = self.redis_client.get(key)
            if value:
                self.logger.info(f"Cache HIT for key: {key}")
                return json.loads(value)
            else:
                self.logger.info(f"Cache MISS for key: {key}")
                return None
        except Exception as e:
            self.logger.error(f"Error getting key {key}: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set value in cache with TTL"""
        if not self.is_connected():
            self.logger.warning("Redis not connected, cannot cache data")
            return False
        
        try:
            ttl = ttl or self.ttl
            serialized_value = json.dumps(value, default=str)  # default=str handles datetime objects
            result = self.redis_client.setex(key, ttl, serialized_value)
            self.logger.info(f"Cached key: {key} (TTL: {ttl}s)")
            return result
        except Exception as e:
            self.logger.error(f"Error setting key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete key from cache"""
        if not self.is_connected():
            return False
        
        try:
            result = self.redis_client.delete(key)
            self.logger.info(f"Deleted key: {key}")
            return result > 0
        except Exception as e:
            self.logger.error(f"Error deleting key {key}: {e}")
            return False
    
    def clear_all(self) -> bool:
        """Clear all keys from current database"""
        if not self.is_connected():
            return False
        
        try:
            self.redis_client.flushdb()
            self.logger.info("Cleared all cache keys")
            return True
        except Exception as e:
            self.logger.error(f"Error clearing cache: {e}")
            return False
    
    def get_stats(self) -> dict:
        """Get cache statistics"""
        if not self.is_connected():
            return {}
        
        try:
            info = self.redis_client.info()
            stats = {
                'keyspace_hits': info.get('keyspace_hits', 0),
                'keyspace_misses': info.get('keyspace_misses', 0),
                'used_memory_human': info.get('used_memory_human', '0B'),
                'connected_clients': info.get('connected_clients', 0),
                'total_keys': len(self.redis_client.keys('*'))
            }
            
            # Calculate hit rate
            total_requests = stats['keyspace_hits'] + stats['keyspace_misses']
            if total_requests > 0:
                stats['hit_rate'] = (stats['keyspace_hits'] / total_requests) * 100
            else:
                stats['hit_rate'] = 0
            
            return stats
        except Exception as e:
            self.logger.error(f"Error getting stats: {e}")
            return {}
    
    def health_check(self) -> dict:
        """Perform health check on Redis connection"""
        status = {
            'connected': False,
            'latency_ms': None,
            'memory_usage': None,
            'error': None
        }
        
        try:
            import time
            start_time = time.time()
            self.redis_client.ping()
            latency = (time.time() - start_time) * 1000
            
            info = self.redis_client.info()
            
            status.update({
                'connected': True,
                'latency_ms': round(latency, 2),
                'memory_usage': info.get('used_memory_human', 'Unknown')
            })
            
        except Exception as e:
            status['error'] = str(e)
        
        return status


# Global cache instance
cache = RedisCache()


def test_redis_connection():
    """Test function to verify Redis connection works"""
    print("Testing Redis connection...")
    
    # Health check
    health = cache.health_check()
    print(f"Health check: {health}")
    
    if not health['connected']:
        print("Redis connection failed!")
        return False
    
    # Test basic operations
    test_key = "test:connection"
    test_value = {"message": "Hello Redis!", "timestamp": "2025-08-21"}
    
    # Set value
    cache.set(test_key, test_value, ttl=10)
    
    # Get value
    retrieved = cache.get(test_key)
    print(f"Retrieved: {retrieved}")
    
    # Clean up
    cache.delete(test_key)
    
    print("Redis connection test completed successfully!")
    return True


if __name__ == "__main__":
    test_redis_connection()
