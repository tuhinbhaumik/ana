@echo off
REM ============================================================
REM ANA - Agentic Network Assistant
REM Start Script for Windows
REM ============================================================
REM Auto-detects whether to run via Docker or source:
REM   - Source found  -> runs Python processes (private/dev repo)
REM   - Source missing -> runs Docker container (public repo)
REM
REM Usage:
REM   scripts\start.bat              Start (auto-detect mode)
REM   scripts\start.bat --backend    Start only backend (source)
REM   scripts\start.bat --frontend   Start only frontend (source)
REM   scripts\start.bat --stop       Stop all ANA processes
REM ============================================================

setlocal enabledelayedexpansion

set DOCKER_IMAGE=ghcr.io/tuhinbhaumik/ana
set DOCKER_TAG=latest
set CONTAINER_NAME=ana

cd /d "%~dp0\.."

REM ── Load .env for port config ─────────────────────
set BACKEND_PORT=9000
set FRONTEND_PORT=8501
if exist ".env" (
    for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
        set "LINE=%%A"
        if not "!LINE:~0,1!"=="#" (
            if "%%A"=="ANA_BACKEND_PORT" set "BACKEND_PORT=%%B"
            if "%%A"=="ANA_FRONTEND_PORT" set "FRONTEND_PORT=%%B"
        )
    )
)
REM Allow env var overrides
if defined ANA_BACKEND_PORT set BACKEND_PORT=%ANA_BACKEND_PORT%
if defined ANA_FRONTEND_PORT set FRONTEND_PORT=%ANA_FRONTEND_PORT%

REM ── Parse arguments ─────────────────────────────────
set START_BACKEND=1
set START_FRONTEND=1

if "%1"=="--backend"  set START_FRONTEND=0
if "%1"=="--frontend" set START_BACKEND=0
if "%1"=="--stop" goto :stop_services

REM ── Detect mode ─────────────────────────────────────
set HAS_SOURCE=0
if exist "app.py" if exist "backend\main.py" set HAS_SOURCE=1

set HAS_DOCKER=0
where docker >nul 2>&1
if %errorlevel% equ 0 set HAS_DOCKER=1

echo.
echo   ============================================================
echo         ANA - Agentic Network Assistant
echo         Backend port:  %BACKEND_PORT%
echo         Frontend port: %FRONTEND_PORT%
echo   ============================================================
echo.

REM ── Branch to mode ──────────────────────────────────
if %HAS_SOURCE% equ 1 goto :source_start
if %HAS_DOCKER% equ 1 goto :docker_start

echo   [FAIL]  No source code found and Docker not installed.
echo           Run scripts\install.bat first, or install Docker.
exit /b 1

REM ══════════════════════════════════════════════════════
REM ── DOCKER START MODE ────────────────────────────────
REM ══════════════════════════════════════════════════════
:docker_start
echo   Mode: Docker container
echo.

REM Check if already running
docker ps --format "{{.Names}}" 2>nul | findstr /r "^%CONTAINER_NAME%$" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] ANA container is already running!
    echo     Frontend:  http://localhost:%FRONTEND_PORT%
    echo     API Docs:  http://localhost:%BACKEND_PORT%/docs
    echo.
    echo   Stop with: scripts\start.bat --stop
    goto :eof
)

REM Remove stopped container if exists
docker rm %CONTAINER_NAME% >nul 2>&1

REM Start container
echo   Starting ANA container...
set DOCKER_CMD=docker run -d --name %CONTAINER_NAME% -p %FRONTEND_PORT%:8501 -p %BACKEND_PORT%:9000 -v ana-data:/app/db
if exist ".env" set DOCKER_CMD=%DOCKER_CMD% --env-file .env
set DOCKER_CMD=%DOCKER_CMD% %DOCKER_IMAGE%:%DOCKER_TAG%

%DOCKER_CMD%

if %errorlevel% neq 0 (
    echo   [FAIL]  Failed to start container
    exit /b 1
)

echo   [OK]    Container started
echo.
echo   Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo   ANA is running! (Docker)
echo.
echo     Frontend:  http://localhost:%FRONTEND_PORT%
echo     API Docs:  http://localhost:%BACKEND_PORT%/docs
echo.
echo   View logs:  docker logs -f %CONTAINER_NAME%
echo   Stop:       scripts\start.bat --stop
echo.

REM Open browser
start http://localhost:%FRONTEND_PORT%
goto :eof

REM ══════════════════════════════════════════════════════
REM ── SOURCE START MODE ────────────────────────────────
REM ══════════════════════════════════════════════════════
:source_start
echo   Mode: Source (Python)
echo.

REM ── Activate venv ───────────────────────────────────
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
) else (
    echo   [WARN] No virtual environment found. Using system Python.
)

REM ── Start Backend ───────────────────────────────────
if %START_BACKEND% equ 1 (
    echo   Starting backend on port %BACKEND_PORT%...
    start "ANA-Backend" cmd /k "cd /d %CD% && venv\Scripts\activate && python -m uvicorn backend.main:app --host 0.0.0.0 --port %BACKEND_PORT% --reload"
    echo   [OK] Backend starting in new window
    echo   Waiting for backend to start...
    timeout /t 5 /nobreak >nul
)

REM ── Start Frontend ──────────────────────────────────
if %START_FRONTEND% equ 1 (
    echo   Starting frontend on port %FRONTEND_PORT%...
    start "ANA-Frontend" cmd /k "cd /d %CD% && venv\Scripts\activate && python -m streamlit run app.py --server.port %FRONTEND_PORT% --server.address 0.0.0.0"
    echo   [OK] Frontend starting in new window
)

REM ── Summary ─────────────────────────────────────────
echo.
echo   ANA is running! (Source)
echo.
if %START_BACKEND% equ 1 (
    echo     Backend:   http://localhost:%BACKEND_PORT%
    echo     API Docs:  http://localhost:%BACKEND_PORT%/docs
)
if %START_FRONTEND% equ 1 (
    echo     Frontend:  http://localhost:%FRONTEND_PORT%
)
echo.
echo   Each service runs in its own window.
echo   Close the windows or run: scripts\start.bat --stop
echo.

REM Open browser after a short delay
if %START_FRONTEND% equ 1 (
    timeout /t 8 /nobreak >nul
    start http://localhost:%FRONTEND_PORT%
)

goto :eof

REM ══════════════════════════════════════════════════════
REM ── STOP SERVICES (both modes) ──────────────────────
REM ══════════════════════════════════════════════════════
:stop_services
echo.
echo   Stopping ANA services...

REM Stop Docker container
docker stop %CONTAINER_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    docker rm %CONTAINER_NAME% >nul 2>&1
    echo   [OK] Docker container stopped
) else (
    echo   Docker container not running
)

REM Stop source mode processes
taskkill /FI "WINDOWTITLE eq ANA-Backend*" /F >nul 2>&1
if %errorlevel% equ 0 (echo   [OK] Backend stopped) else (echo   Backend not running)
taskkill /FI "WINDOWTITLE eq ANA-Frontend*" /F >nul 2>&1
if %errorlevel% equ 0 (echo   [OK] Frontend stopped) else (echo   Frontend not running)

echo   Done.
echo.

endlocal
