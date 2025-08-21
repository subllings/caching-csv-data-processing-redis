@echo off
REM Airline Data Analyzer with Redis Caching - Windows Setup Script
setlocal enabledelayedexpansion

echo.
echo ================================================================
echo   🛫 Airline Data Analyzer with Redis Caching
echo   Windows Environment Setup Script
echo ================================================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found! Please install Python 3.8+ first.
    echo    Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python found: %PYTHON_VERSION%

REM Check if pip is installed
pip --version >nul 2>&1
if errorlevel 1 (
    echo ❌ pip not found! Please install pip first.
    pause
    exit /b 1
)

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️ Docker not found. Redis will need to be installed manually.
    set DOCKER_AVAILABLE=false
) else (
    for /f "tokens=3" %%i in ('docker --version 2^>^&1') do set DOCKER_VERSION=%%i
    echo ✅ Docker found: %DOCKER_VERSION%
    set DOCKER_AVAILABLE=true
)

echo.
echo 📦 Setting up Python virtual environment...

REM Remove existing virtual environment
if exist venv (
    echo ⚠️ Removing existing virtual environment...
    rmdir /s /q venv
)

REM Create virtual environment
echo 🔧 Creating virtual environment...
python -m venv venv

REM Activate virtual environment
echo 🔋 Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo 📈 Upgrading pip...
python -m pip install --upgrade pip

REM Install requirements
echo 📦 Installing Python packages...
if exist requirements.txt (
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ Failed to install Python packages!
        pause
        exit /b 1
    )
    echo ✅ All Python packages installed successfully
) else (
    echo ❌ requirements.txt not found!
    pause
    exit /b 1
)

echo.
echo 🐳 Setting up Redis...

if "%DOCKER_AVAILABLE%"=="true" (
    echo 🔧 Starting Redis with Docker...
    docker-compose up -d redis
    if errorlevel 1 (
        echo ⚠️ Failed to start Redis with Docker
    ) else (
        echo ✅ Redis started successfully
        timeout /t 3 /nobreak >nul
        
        REM Test Redis connection
        docker-compose exec redis redis-cli ping >nul 2>&1
        if errorlevel 1 (
            echo ⚠️ Redis connection test failed
        ) else (
            echo ✅ Redis is running and accessible
        )
    )
) else (
    echo ⚠️ Docker not available. Please install Redis manually:
    echo    Download from: https://github.com/microsoftarchive/redis/releases
)

echo.
echo 📁 Setting up project structure...

REM Create directories
if not exist data mkdir data
if not exist app mkdir app

echo ✅ Project structure ready

echo.
echo 🧪 Testing the setup...

REM Test Python imports
python -c "import redis, pandas, numpy, click, rich" >nul 2>&1
if errorlevel 1 (
    echo ❌ Some Python packages failed to import
    pause
    exit /b 1
) else (
    echo ✅ All Python packages imported successfully
)

REM Test Redis connection
cd app
python -c "import sys; sys.path.append('.'); from cache import cache; health = cache.health_check(); exit(0 if health['connected'] else 1)" >nul 2>&1
if errorlevel 1 (
    echo ⚠️ Redis connection test failed - Redis might not be running
) else (
    echo ✅ Redis connection test passed
)
cd ..

echo.
echo 📝 Creating activation script...

REM Create Windows activation script
(
echo @echo off
echo call venv\Scripts\activate.bat
echo echo.
echo echo 🛫 Airline Data Analyzer environment activated!
echo echo.
echo echo Available commands:
echo echo   🚀 python app/main.py demo      - Run automated demo
echo echo   📊 python app/main.py analyze   - Interactive analysis
echo echo   🔧 python app/main.py test      - Test Redis connection
echo echo   🐳 docker-compose up -d redis   - Start Redis
echo echo   🧹 docker-compose down          - Stop Redis
echo echo.
echo echo Quick start: cd app ^&^& python main.py demo
echo echo.
) > activate-env.bat

echo ✅ Created activate-env.bat script

echo.
echo ================================================================
echo                    SETUP SUCCESSFUL! 🎉
echo ================================================================
echo.

echo 📋 QUICK START:
echo.
echo 1. Activate environment:
echo    activate-env.bat
echo.
echo 2. Start Redis (if not already running):
if "%DOCKER_AVAILABLE%"=="true" (
    echo    docker-compose up -d redis
) else (
    echo    # Install and start Redis manually
)
echo.
echo 3. Run the application:
echo    cd app
echo    python main.py demo          # Quick demonstration
echo    python main.py analyze       # Interactive analysis
echo    python main.py test          # Test connection
echo.

echo 📊 WHAT'S INCLUDED:
echo ✅ Python virtual environment with all dependencies
echo ✅ Redis caching system
echo ✅ Sample airline dataset (auto-generated)
echo ✅ Interactive CLI interface
echo ✅ Performance benchmarking
echo ✅ Comprehensive logging
echo.

echo 🆘 TROUBLESHOOTING:
echo • If Redis connection fails: docker-compose restart redis
echo • If Python imports fail: activate-env.bat
echo • For detailed logs: docker-compose logs redis
echo.

echo Happy coding! 🚀
echo.

REM Save environment info
(
echo # Environment setup information
echo SETUP_DATE=%date% %time%
echo PYTHON_VERSION=%PYTHON_VERSION%
echo DOCKER_AVAILABLE=%DOCKER_AVAILABLE%
echo OS=Windows
) > .env-info

echo ✅ Environment info saved to .env-info
echo.
pause
