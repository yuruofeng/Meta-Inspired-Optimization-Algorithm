@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================================
echo         Metaheuristic Optimization Platform v2.0
echo         (Yuan Qi Fa Shi You Hua Suan Fa Ping Tai)
echo ========================================================
echo         One-Click Start Script
echo ========================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

echo [Check] Python environment...
python --version >nul 2>&1
if errorlevel 1 (
    echo [Error] Python not found. Please install Python 3.10+
    echo         Download: https://www.python.org/downloads/
    pause
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [OK] Python %PYTHON_VERSION%

echo [Check] Node.js environment...
node --version >nul 2>&1
if errorlevel 1 (
    echo [Error] Node.js not found. Please install Node.js 18+
    echo         Download: https://nodejs.org/
    pause
    exit /b 1
)
for /f %%i in ('node --version') do set NODE_VERSION=%%i
echo [OK] Node.js %NODE_VERSION%

echo.
echo ========================================================
echo  Install Dependencies
echo ========================================================

echo.
echo [1/4] Checking Python dependencies...
cd /d "%PROJECT_ROOT%\api_server"
if exist "requirements.txt" (
    python -c "import fastapi" 2>nul
    if errorlevel 1 (
        echo [Install] Installing dependencies...
        pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple 2>nul
        if errorlevel 1 (
            echo [Warning] Dependency installation may need manual retry
        ) else (
            echo [OK] Dependencies installed
        )
    ) else (
        echo [Skip] Dependencies already installed
    )
) else (
    echo [Warning] requirements.txt not found
)

echo.
echo [2/4] Checking Node.js dependencies...
cd /d "%PROJECT_ROOT%\web-frontend"
if exist "package.json" (
    if not exist "node_modules" (
        echo [Install] Installing npm packages...
        call npm install --silent >nul 2>&1
        if errorlevel 1 (
            echo [Warning] npm install may need retry
        ) else (
            echo [OK] npm packages installed
        )
    ) else (
        echo [Skip] node_modules exists
    )
) else (
    echo [Warning] package.json not found
)

echo.
echo ========================================================
echo  Start Services
echo ========================================================

echo.
echo [3/4] Starting API server (port 8000)...
cd /d "%PROJECT_ROOT%\api_server"
start "Metaheuristic API Server" cmd /k "chcp 65001 >nul && python main.py"
if errorlevel 1 (
    echo [Error] Failed to start API server
    pause
    exit /b 1
)
echo [OK] API server started in new window

echo [Wait] Waiting for API server initialization...
timeout /t 3 /nobreak >nul

echo.
echo [4/4] Starting frontend dev server (port 5173)...
cd /d "%PROJECT_ROOT%\web-frontend"
start "Metaheuristic Frontend" cmd /k "chcp 65001 >nul && npm run dev"
if errorlevel 1 (
    echo [Error] Failed to start frontend server
    pause
    exit /b 1
)
echo [OK] Frontend server started in new window

cd /d "%PROJECT_ROOT%"

echo.
echo ========================================================
echo                    Startup Complete!
echo ========================================================
echo   Frontend:  http://localhost:5173
echo   API Docs:  http://localhost:8000/docs
echo   Health:    http://localhost:8000/health
echo ========================================================
echo   Stop: Run stop.bat or close the windows
echo ========================================================
echo.

echo Opening browser...
timeout /t 2 /nobreak >nul
start http://localhost:5173

echo.
echo Press any key to close this window (services will continue)...
pause >nul
