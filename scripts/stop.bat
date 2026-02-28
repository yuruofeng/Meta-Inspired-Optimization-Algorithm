@echo off
echo.
echo ========================================================
echo         元启发式优化算法平台 v2.0
echo         停止所有服务
echo ========================================================
echo.

echo [停止] 正在停止后端API服务...
taskkill /f /fi "WINDOWTITLE eq Metaheuristic API Server*" >nul 2>&1
taskkill /f /im python.exe /fi "WINDOWTITLE eq *main.py*" >nul 2>&1

echo [停止] 正在停止前端开发服务...
taskkill /f /fi "WINDOWTITLE eq Metaheuristic Frontend*" >nul 2>&1
taskkill /f /im node.exe /fi "WINDOWTITLE eq *vite*" >nul 2>&1

echo.
echo ========================================================
echo                    服务已停止
echo ========================================================
echo.

pause
