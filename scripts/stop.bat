@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================================
echo         Metaheuristic Optimization Platform
echo         Stop Services Script
echo ========================================================
echo.

echo [Stop] Stopping backend API server...
taskkill /f /im python.exe /fi "WINDOWTITLE eq *Metaheuristic API*" >nul 2>&1
taskkill /f /im python.exe /fi "WINDOWTITLE eq *uvicorn*" >nul 2>&1

echo [Stop] Stopping frontend dev server...
taskkill /f /im node.exe /fi "WINDOWTITLE eq *Metaheuristic Frontend*" >nul 2>&1
taskkill /f /im node.exe /fi "WINDOWTITLE eq *vite*" >nul 2>&1

echo.
echo ========================================================
echo                    Services Stopped
echo ========================================================
echo.

pause
