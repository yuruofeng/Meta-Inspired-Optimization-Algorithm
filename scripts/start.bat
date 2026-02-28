@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================================
echo         元启发式优化算法平台 v2.0
echo         Metaheuristic Optimization Platform
echo ========================================================
echo         一键启动脚本
echo ========================================================
echo.

:: 获取项目根目录（脚本在 scripts/ 子目录下）
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

:: 检查Python
echo [检查] Python环境...
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到Python，请先安装Python 3.10或更高版本
    echo        下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [成功] Python %PYTHON_VERSION%

:: 检查Node.js
echo [检查] Node.js环境...
node --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到Node.js，请先安装Node.js 18或更高版本
    echo        下载地址: https://nodejs.org/
    pause
    exit /b 1
)
for /f %%i in ('node --version') do set NODE_VERSION=%%i
echo [成功] Node.js %NODE_VERSION%

echo.
echo ========================================================
echo  安装依赖
echo ========================================================

:: 安装后端依赖
echo.
echo [1/4] 检查后端Python依赖...
cd /d "%PROJECT_ROOT%\api_server"
if not exist "requirements.txt" (
    echo [警告] 未找到 requirements.txt
) else (
    python -c "import fastapi" 2>nul
    if errorlevel 1 (
        echo [安装] 正在安装依赖...
        pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple 2>nul
        if errorlevel 1 (
            echo [警告] 部分依赖安装失败，可能需要手动安装
        ) else (
            echo [成功] 后端依赖安装完成
        )
    ) else (
        echo [跳过] 依赖已安装
    )
)

:: 安装前端依赖
echo.
echo [2/4] 检查前端Node.js依赖...
cd /d "%PROJECT_ROOT%\web-frontend"
if not exist "package.json" (
    echo [警告] 未找到 package.json
) else (
    call npm install --silent >nul 2>&1
    if errorlevel 1 (
        echo [警告] 前端依赖安装可能需要检查
    ) else (
        echo [成功] 前端依赖安装完成
    )
)

echo.
echo ========================================================
echo  启动服务
echo ========================================================

:: 启动后端
echo.
echo [3/4] 启动后端API服务 (端口 8000)...
cd /d "%PROJECT_ROOT%\api_server"
start "Metaheuristic API Server" cmd /k "python main.py"
if errorlevel 1 (
    echo [错误] 后端启动失败
    pause
    exit /b 1
)
echo [成功] 后端服务已在新窗口启动

:: 等待后端启动
echo [等待] 等待后端服务初始化...
timeout /t 3 /nobreak >nul

:: 启动前端
echo.
echo [4/4] 启动前端开发服务 (端口 5173)...
cd /d "%PROJECT_ROOT%\web-frontend"
start "Metaheuristic Frontend" cmd /k "npm run dev"
if errorlevel 1 (
    echo [错误] 前端启动失败
    pause
    exit /b 1
)
echo [成功] 前端服务已在新窗口启动

:: 返回根目录
cd /d "%PROJECT_ROOT%"

echo.
echo ========================================================
echo                    启动完成！
echo ========================================================
echo   前端界面: http://localhost:5173
echo   API文档:  http://localhost:8000/docs
echo   健康检查: http://localhost:8000/health
echo ========================================================
echo   停止服务: 运行 stop.bat 或关闭命令窗口
echo ========================================================
echo.

:: 尝试自动打开浏览器
echo Opening browser...
timeout /t 2 /nobreak >nul
start http://localhost:5173

echo.
echo Press any key to close this window (services will continue)...
pause >nul
