"""
Airline Data Analyzer with Redis Caching
A Python application that processes airline delay data with Redis caching for performance optimization.
"""

import pandas as pd
import numpy as np
import time
import logging
import os
from typing import Dict, Any, Optional, List
from datetime import datetime
import click
from rich.console import Console
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.panel import Panel

from cache import cache

# Set up rich console for beautiful output
console = Console()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class AirlineDataAnalyzer:
    """Main class for analyzing airline data with Redis caching"""
    
    def __init__(self, csv_file_path: str):
        self.csv_file_path = csv_file_path
        self.data = None
        self.cache = cache
        
        # Performance tracking
        self.query_times = {}
        
    def load_data(self) -> bool:
        """Load CSV data into memory"""
        try:
            console.print("📊 Loading airline data...", style="blue")
            
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                console=console,
            ) as progress:
                task = progress.add_task("Loading CSV data...", total=None)
                
                start_time = time.time()
                
                # Check if file exists
                if not os.path.exists(self.csv_file_path):
                    # Create sample data if file doesn't exist
                    console.print("⚠️ CSV file not found. Creating sample data...", style="yellow")
                    self._create_sample_data()
                
                # Load the data
                self.data = pd.read_csv(self.csv_file_path)
                load_time = time.time() - start_time
                
                progress.update(task, completed=True)
            
            # Display data info
            console.print(f"✅ Data loaded successfully in {load_time:.2f}s", style="green")
            console.print(f"📈 Dataset shape: {self.data.shape[0]:,} rows × {self.data.shape[1]} columns")
            
            # Show sample of the data
            self._display_data_sample()
            
            return True
            
        except Exception as e:
            console.print(f"❌ Error loading data: {e}", style="red")
            logger.error(f"Failed to load data: {e}")
            return False
    
    def _create_sample_data(self):
        """Create sample airline data for demonstration"""
        console.print("🔧 Generating sample airline data...", style="cyan")
        
        # Sample data generation
        np.random.seed(42)
        n_flights = 100000  # 100k sample flights
        
        airlines = ['AA', 'DL', 'UA', 'WN', 'AS', 'B6', 'NK', 'F9', 'G4', 'HA']
        airports = ['ATL', 'LAX', 'ORD', 'DFW', 'DEN', 'JFK', 'SFO', 'SEA', 'LAS', 'MCO', 
                   'EWR', 'CLT', 'PHX', 'IAH', 'MIA', 'BOS', 'MSP', 'FLL', 'DTW', 'PHL']
        
        # Generate sample data
        data = {
            'FL_DATE': pd.date_range('2024-01-01', '2024-12-31', freq='H')[:n_flights],
            'OP_CARRIER': np.random.choice(airlines, n_flights),
            'ORIGIN': np.random.choice(airports, n_flights),
            'DEST': np.random.choice(airports, n_flights),
            'DEP_DELAY': np.random.normal(15, 45, n_flights).round(1),  # Average 15min delay, std 45min
            'ARR_DELAY': np.random.normal(12, 40, n_flights).round(1),  # Average 12min delay, std 40min
            'DISTANCE': np.random.uniform(200, 3000, n_flights).round(0),
            'AIR_TIME': np.random.uniform(30, 360, n_flights).round(0)
        }
        
        # Create DataFrame and save
        sample_df = pd.DataFrame(data)
        sample_df['MONTH'] = sample_df['FL_DATE'].dt.month
        sample_df['DAY_OF_WEEK'] = sample_df['FL_DATE'].dt.dayofweek
        
        # Ensure destination directory exists
        os.makedirs(os.path.dirname(self.csv_file_path), exist_ok=True)
        sample_df.to_csv(self.csv_file_path, index=False)
        
        console.print(f"✅ Sample data created: {n_flights:,} flights saved to {self.csv_file_path}", style="green")
    
    def _display_data_sample(self):
        """Display a sample of the loaded data"""
        if self.data is not None:
            table = Table(title="Data Sample (First 5 rows)")
            
            # Add columns
            for col in self.data.columns[:8]:  # Show first 8 columns
                table.add_column(col, style="cyan")
            
            # Add rows
            for _, row in self.data.head().iterrows():
                table.add_row(*[str(row[col]) for col in self.data.columns[:8]])
            
            console.print(table)
    
    def _generate_cache_key(self, query_type: str, **params) -> str:
        """Generate a unique cache key for the query"""
        key_parts = [f"airline_data:{query_type}"]
        for k, v in sorted(params.items()):
            if v is not None:
                key_parts.append(f"{k}:{v}")
        return ":".join(key_parts)
    
    def _track_query_time(self, query_name: str, execution_time: float, from_cache: bool):
        """Track query execution times for performance analysis"""
        if query_name not in self.query_times:
            self.query_times[query_name] = {'cache': [], 'csv': []}
        
        if from_cache:
            self.query_times[query_name]['cache'].append(execution_time)
        else:
            self.query_times[query_name]['csv'].append(execution_time)
    
    def get_average_delay_per_airline(self, delay_type: str = 'ARR_DELAY') -> Dict[str, float]:
        """
        Calculate average delay per airline with caching
        
        Args:
            delay_type: 'ARR_DELAY' or 'DEP_DELAY'
        """
        cache_key = self._generate_cache_key('avg_delay_airline', delay_type=delay_type)
        
        # Try to get from cache first
        start_time = time.time()
        cached_result = self.cache.get(cache_key)
        
        if cached_result is not None:
            execution_time = time.time() - start_time
            self._track_query_time('avg_delay_airline', execution_time, from_cache=True)
            console.print("🎯 Retrieved from Redis cache", style="green")
            return cached_result
        
        # Calculate from CSV
        console.print("📊 Computing from CSV data...", style="yellow")
        
        try:
            # Simulate expensive computation with some processing time
            time.sleep(0.5)  # Simulate processing delay
            
            result = self.data.groupby('OP_CARRIER')[delay_type].mean().round(2).to_dict()
            
            execution_time = time.time() - start_time
            self._track_query_time('avg_delay_airline', execution_time, from_cache=False)
            
            # Cache the result
            self.cache.set(cache_key, result)
            console.print("💾 Result cached in Redis", style="blue")
            
            return result
            
        except Exception as e:
            logger.error(f"Error calculating average delay per airline: {e}")
            return {}
    
    def get_flights_per_airport(self, airport_type: str = 'ORIGIN') -> Dict[str, int]:
        """
        Calculate total flights per airport with caching
        
        Args:
            airport_type: 'ORIGIN' or 'DEST'
        """
        cache_key = self._generate_cache_key('flights_airport', airport_type=airport_type)
        
        # Try cache first
        start_time = time.time()
        cached_result = self.cache.get(cache_key)
        
        if cached_result is not None:
            execution_time = time.time() - start_time
            self._track_query_time('flights_airport', execution_time, from_cache=True)
            console.print("🎯 Retrieved from Redis cache", style="green")
            return cached_result
        
        # Calculate from CSV
        console.print("📊 Computing from CSV data...", style="yellow")
        
        try:
            time.sleep(0.3)  # Simulate processing delay
            
            result = self.data[airport_type].value_counts().to_dict()
            
            execution_time = time.time() - start_time
            self._track_query_time('flights_airport', execution_time, from_cache=False)
            
            # Cache the result
            self.cache.set(cache_key, result)
            console.print("💾 Result cached in Redis", style="blue")
            
            return result
            
        except Exception as e:
            logger.error(f"Error calculating flights per airport: {e}")
            return {}
    
    def get_delay_stats_by_month(self) -> Dict[str, Dict[str, float]]:
        """Calculate delay statistics by month with caching"""
        cache_key = self._generate_cache_key('delay_stats_month')
        
        # Try cache first
        start_time = time.time()
        cached_result = self.cache.get(cache_key)
        
        if cached_result is not None:
            execution_time = time.time() - start_time
            self._track_query_time('delay_stats_month', execution_time, from_cache=True)
            console.print("🎯 Retrieved from Redis cache", style="green")
            return cached_result
        
        # Calculate from CSV
        console.print("📊 Computing from CSV data...", style="yellow")
        
        try:
            time.sleep(0.7)  # Simulate processing delay
            
            # Calculate monthly statistics
            monthly_stats = self.data.groupby('MONTH').agg({
                'ARR_DELAY': ['mean', 'median', 'std'],
                'DEP_DELAY': ['mean', 'median', 'std']
            }).round(2)
            
            # Flatten column names and convert to dict
            monthly_stats.columns = ['_'.join(col).strip() for col in monthly_stats.columns]
            result = monthly_stats.to_dict('index')
            
            execution_time = time.time() - start_time
            self._track_query_time('delay_stats_month', execution_time, from_cache=False)
            
            # Cache the result
            self.cache.set(cache_key, result)
            console.print("💾 Result cached in Redis", style="blue")
            
            return result
            
        except Exception as e:
            logger.error(f"Error calculating monthly delay stats: {e}")
            return {}
    
    def get_airline_performance_summary(self) -> Dict[str, Dict[str, Any]]:
        """Get comprehensive airline performance summary with caching"""
        cache_key = self._generate_cache_key('airline_performance_summary')
        
        # Try cache first
        start_time = time.time()
        cached_result = self.cache.get(cache_key)
        
        if cached_result is not None:
            execution_time = time.time() - start_time
            self._track_query_time('airline_performance', execution_time, from_cache=True)
            console.print("🎯 Retrieved from Redis cache", style="green")
            return cached_result
        
        # Calculate from CSV
        console.print("📊 Computing comprehensive airline performance...", style="yellow")
        
        try:
            time.sleep(1.0)  # Simulate expensive computation
            
            # Calculate comprehensive stats per airline
            airline_stats = self.data.groupby('OP_CARRIER').agg({
                'ARR_DELAY': ['mean', 'median', 'std', 'count'],
                'DEP_DELAY': ['mean', 'median', 'std'],
                'DISTANCE': ['mean', 'sum'],
                'AIR_TIME': 'mean'
            }).round(2)
            
            # Flatten column names
            airline_stats.columns = ['_'.join(col).strip() for col in airline_stats.columns]
            
            # Add on-time performance (flights with delay <= 15 minutes)
            on_time_stats = self.data.groupby('OP_CARRIER').apply(
                lambda x: ((x['ARR_DELAY'] <= 15).sum() / len(x) * 100).round(2)
            ).to_dict()
            
            # Combine all stats
            result = {}
            for airline in airline_stats.index:
                stats = airline_stats.loc[airline].to_dict()
                stats['on_time_percentage'] = on_time_stats[airline]
                result[airline] = stats
            
            execution_time = time.time() - start_time
            self._track_query_time('airline_performance', execution_time, from_cache=False)
            
            # Cache the result
            self.cache.set(cache_key, result)
            console.print("💾 Result cached in Redis", style="blue")
            
            return result
            
        except Exception as e:
            logger.error(f"Error calculating airline performance summary: {e}")
            return {}
    
    def display_results(self, data: Dict, title: str, limit: int = 10):
        """Display results in a formatted table"""
        if not data:
            console.print("No data to display", style="red")
            return
        
        table = Table(title=title)
        
        # Handle different data structures
        if isinstance(list(data.values())[0], dict):
            # Multi-column data (like airline performance)
            table.add_column("Item", style="cyan", width=8)
            
            # Get all possible columns from the data
            all_columns = set()
            for item_data in data.values():
                all_columns.update(item_data.keys())
            
            # Add columns for each metric
            for col in sorted(all_columns):
                table.add_column(col.replace('_', ' ').title(), style="magenta")
            
            # Add rows (limit to top N)
            for i, (item, item_data) in enumerate(data.items()):
                if i >= limit:
                    break
                row = [str(item)]
                for col in sorted(all_columns):
                    value = item_data.get(col, 'N/A')
                    if isinstance(value, float):
                        row.append(f"{value:.2f}")
                    else:
                        row.append(str(value))
                table.add_row(*row)
        
        else:
            # Simple key-value data
            table.add_column("Item", style="cyan", width=12)
            table.add_column("Value", style="magenta")
            
            # Sort by value and limit results
            sorted_data = sorted(data.items(), key=lambda x: x[1], reverse=True)[:limit]
            
            for key, value in sorted_data:
                if isinstance(value, float):
                    table.add_row(str(key), f"{value:.2f}")
                else:
                    table.add_row(str(key), f"{value:,}")
        
        console.print(table)
    
    def show_performance_summary(self):
        """Display performance comparison between cache and CSV"""
        if not self.query_times:
            console.print("No performance data available yet", style="yellow")
            return
        
        table = Table(title="Performance Summary (Cache vs CSV)")
        table.add_column("Query Type", style="cyan")
        table.add_column("CSV Time (avg)", style="red")
        table.add_column("Cache Time (avg)", style="green")
        table.add_column("Speedup", style="magenta")
        table.add_column("Cache Hits", style="blue")
        
        for query_name, times in self.query_times.items():
            csv_times = times['csv']
            cache_times = times['cache']
            
            if csv_times and cache_times:
                avg_csv = sum(csv_times) / len(csv_times)
                avg_cache = sum(cache_times) / len(cache_times)
                speedup = avg_csv / avg_cache if avg_cache > 0 else 0
                
                table.add_row(
                    query_name,
                    f"{avg_csv:.3f}s",
                    f"{avg_cache:.3f}s",
                    f"{speedup:.1f}x",
                    str(len(cache_times))
                )
        
        console.print(table)
        
        # Show Redis stats
        redis_stats = self.cache.get_stats()
        if redis_stats:
            stats_panel = Panel(
                f"Total Keys: {redis_stats.get('total_keys', 0)}\n"
                f"Cache Hits: {redis_stats.get('keyspace_hits', 0):,}\n"
                f"Cache Misses: {redis_stats.get('keyspace_misses', 0):,}\n"
                f"Hit Rate: {redis_stats.get('hit_rate', 0):.1f}%\n"
                f"Memory Usage: {redis_stats.get('used_memory_human', 'Unknown')}",
                title="Redis Statistics",
                style="blue"
            )
            console.print(stats_panel)
    
    def clear_cache(self):
        """Clear all cached data"""
        success = self.cache.clear_all()
        if success:
            console.print("🧹 Cache cleared successfully", style="green")
        else:
            console.print("❌ Failed to clear cache", style="red")


# CLI Interface
@click.group()
def cli():
    """Airline Data Analyzer with Redis Caching"""
    pass


@cli.command()
@click.option('--csv-file', default='data/flights.csv', help='Path to CSV file')
def analyze(csv_file):
    """Run interactive analysis session"""
    console.print(Panel("🛫 Airline Data Analyzer with Redis Caching", style="bold blue"))
    
    # Initialize analyzer
    analyzer = AirlineDataAnalyzer(csv_file)
    
    # Load data
    if not analyzer.load_data():
        return
    
    # Check Redis connection
    health = analyzer.cache.health_check()
    if health['connected']:
        console.print(f"✅ Redis connected (latency: {health['latency_ms']}ms)", style="green")
    else:
        console.print(f"❌ Redis connection failed: {health['error']}", style="red")
        return
    
    # Interactive menu
    while True:
        console.print("\n" + "="*50)
        console.print("Select an analysis option:", style="bold")
        console.print("1. Average Arrival Delay per Airline")
        console.print("2. Average Departure Delay per Airline") 
        console.print("3. Total Flights per Origin Airport")
        console.print("4. Total Flights per Destination Airport")
        console.print("5. Monthly Delay Statistics")
        console.print("6. Comprehensive Airline Performance")
        console.print("7. Show Performance Summary")
        console.print("8. Clear Cache")
        console.print("9. Exit")
        
        choice = click.prompt("Enter your choice", type=int)
        
        if choice == 1:
            console.print("\n📊 Computing Average Arrival Delay per Airline...")
            result = analyzer.get_average_delay_per_airline('ARR_DELAY')
            analyzer.display_results(result, "Average Arrival Delay per Airline (minutes)")
            
        elif choice == 2:
            console.print("\n📊 Computing Average Departure Delay per Airline...")
            result = analyzer.get_average_delay_per_airline('DEP_DELAY')
            analyzer.display_results(result, "Average Departure Delay per Airline (minutes)")
            
        elif choice == 3:
            console.print("\n📊 Computing Total Flights per Origin Airport...")
            result = analyzer.get_flights_per_airport('ORIGIN')
            analyzer.display_results(result, "Total Flights per Origin Airport")
            
        elif choice == 4:
            console.print("\n📊 Computing Total Flights per Destination Airport...")
            result = analyzer.get_flights_per_airport('DEST')
            analyzer.display_results(result, "Total Flights per Destination Airport")
            
        elif choice == 5:
            console.print("\n📊 Computing Monthly Delay Statistics...")
            result = analyzer.get_delay_stats_by_month()
            analyzer.display_results(result, "Monthly Delay Statistics", limit=12)
            
        elif choice == 6:
            console.print("\n📊 Computing Comprehensive Airline Performance...")
            result = analyzer.get_airline_performance_summary()
            analyzer.display_results(result, "Comprehensive Airline Performance Summary")
            
        elif choice == 7:
            analyzer.show_performance_summary()
            
        elif choice == 8:
            analyzer.clear_cache()
            
        elif choice == 9:
            console.print("👋 Goodbye!", style="blue")
            break
            
        else:
            console.print("Invalid choice. Please try again.", style="red")


@cli.command()
@click.option('--csv-file', default='data/flights.csv', help='Path to CSV file')
def demo(csv_file):
    """Run automated demo showing cache performance"""
    console.print(Panel("🚀 Automated Demo: Cache Performance", style="bold green"))
    
    analyzer = AirlineDataAnalyzer(csv_file)
    
    if not analyzer.load_data():
        return
    
    # Clear cache to start fresh
    analyzer.clear_cache()
    
    console.print("\n🎯 Demo: Running same query twice to show cache performance\n")
    
    # First run (from CSV)
    console.print("📊 First run (computing from CSV):", style="bold yellow")
    start_time = time.time()
    result1 = analyzer.get_average_delay_per_airline('ARR_DELAY')
    first_run_time = time.time() - start_time
    
    # Second run (from cache)
    console.print("\n📊 Second run (retrieving from cache):", style="bold green")
    start_time = time.time()
    result2 = analyzer.get_average_delay_per_airline('ARR_DELAY')
    second_run_time = time.time() - start_time
    
    # Show results
    analyzer.display_results(result1, "Average Arrival Delay per Airline")
    
    # Performance comparison
    speedup = first_run_time / second_run_time if second_run_time > 0 else 0
    
    perf_panel = Panel(
        f"First Run (CSV): {first_run_time:.3f} seconds\n"
        f"Second Run (Cache): {second_run_time:.3f} seconds\n"
        f"Speedup: {speedup:.1f}x faster with cache! 🚀",
        title="Performance Comparison",
        style="bold magenta"
    )
    console.print(perf_panel)


@cli.command()
def test():
    """Test Redis connection"""
    console.print("🔧 Testing Redis connection...")
    
    health = cache.health_check()
    console.print(f"Connection status: {health}")
    
    if health['connected']:
        console.print("✅ Redis is working perfectly!", style="green")
        
        # Show some stats
        stats = cache.get_stats()
        console.print(f"📊 Redis Stats: {stats}")
    else:
        console.print("❌ Redis connection failed!", style="red")


if __name__ == "__main__":
    cli()
