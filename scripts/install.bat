@echo off
REM ============================================================
REM ANA - Agentic Network Assistant
REM Automated Installer for Windows
REM ============================================================
REM Auto-detects whether source code is present:
REM   - Source found  -> Python venv install (private/dev repo)
REM   - Source missing -> Docker pull from GHCR (public repo)
REM
REM Usage:
REM   scripts\install.bat              Auto-detect mode
REM   scripts\install.bat --docker     Force Docker mode
REM   scripts\install.bat --source     Force source mode
REM ============================================================

setlocal enabledelayedexpansion

set DOCKER_IMAGE=ghcr.io/tuhinbhaumik/ana
set DOCKER_TAG=latest
set CONTAINER_NAME=ana

echo.
echo   ============================================================
echo         ANA - Agentic Network Assistant
echo         Installer for Windows
echo   ============================================================
echo.

REM ── Navigate to project root ────────────────────────
cd /d "%~dp0\.."
echo   Project root: %CD%
echo.

REM ── Detect environment ──────────────────────────────
echo   [INFO]  Detecting environment...
echo   OS:           Windows %OS%
echo   Architecture: %PROCESSOR_ARCHITECTURE%

REM ── Check for source code ───────────────────────────
set HAS_SOURCE=0
if exist "app.py" if exist "backend\main.py" set HAS_SOURCE=1

REM ── Check for Docker ────────────────────────────────
set HAS_DOCKER=0
where docker >nul 2>&1
if %errorlevel% equ 0 set HAS_DOCKER=1

REM ── Determine install mode ──────────────────────────
set INSTALL_MODE=auto
if "%1"=="--docker" set INSTALL_MODE=docker
if "%1"=="--source" set INSTALL_MODE=source

if "%INSTALL_MODE%"=="auto" (
    if %HAS_SOURCE% equ 1 (
        set INSTALL_MODE=source
    ) else if %HAS_DOCKER% equ 1 (
        set INSTALL_MODE=docker
    ) else (
        echo   [FAIL]  No source code found and Docker not installed.
        echo           Install Docker from https://docker.com or use the full source repo.
        exit /b 1
    )
)

echo.
echo   Install mode:   %INSTALL_MODE%
if %HAS_SOURCE% equ 1 (echo   Source code:   Found) else (echo   Source code:   Not found)
if %HAS_DOCKER% equ 1 (echo   Docker:        Available) else (echo   Docker:        Not installed)
echo.

REM ── Branch to install mode ──────────────────────────
if "%INSTALL_MODE%"=="docker" goto :docker_install
if "%INSTALL_MODE%"=="source" goto :source_install
goto :eof

REM ══════════════════════════════════════════════════════
REM ── DOCKER INSTALL MODE ──────────────────────────────
REM ══════════════════════════════════════════════════════
:docker_install

if %HAS_DOCKER% equ 0 (
    echo   [FAIL]  Docker is required for this install mode.
    echo           Install from https://docker.com
    exit /b 1
)

echo   [INFO]  Pulling ANA Docker image from GHCR...
docker pull %DOCKER_IMAGE%:%DOCKER_TAG%
if %errorlevel% neq 0 (
    echo   [FAIL]  Failed to pull Docker image
    exit /b 1
)
echo   [OK]    Image pulled: %DOCKER_IMAGE%:%DOCKER_TAG%

REM Create .env if needed
if not exist ".env" (
    if exist ".env.example" (
        copy .env.example .env >nul
        echo   [OK]    Created .env from .env.example
    ) else (
        (
            echo # ANA Environment Configuration
            echo # GEMINI_API_KEY=your_key_here
        ) > .env
        echo   [OK]    Created default .env
    )
    echo   [WARN]  Edit .env to set your API keys ^(optional for AI features^)
)

echo.
echo   ============================================================
echo            Installation Complete! (Docker)
echo   ============================================================
echo.
echo   Start the application:
echo     scripts\start.bat
echo.
echo   Or manually:
echo     docker run -d --name %CONTAINER_NAME% -p 8501:8501 -p 9000:9000 --env-file .env -v ana-data:/app/db %DOCKER_IMAGE%:%DOCKER_TAG%
echo.
echo   Access:
echo     Frontend:  http://localhost:8501
echo     API Docs:  http://localhost:9000/docs
echo.
echo   Default Logins:
echo     admin / admin123        (Full access)
echo     operator1 / operator123  (Operator)
echo     approver1 / approver123  (Approver)
echo     demo / demo              (Read-only demo)
echo.
goto :eof

REM ══════════════════════════════════════════════════════
REM ── SOURCE INSTALL MODE ──────────────────────────────
REM ══════════════════════════════════════════════════════
:source_install

if %HAS_SOURCE% equ 0 (
    echo   [FAIL]  Source code not found. Use --docker mode or clone the full source repo.
    exit /b 1
)

REM ── Detect Python ───────────────────────────────────
set PYTHON_CMD=
where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PY_VER=%%v
    set PYTHON_CMD=python
) else (
    where python3 >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=2" %%v in ('python3 --version 2^>^&1') do set PY_VER=%%v
        set PYTHON_CMD=python3
    )
)

if "%PYTHON_CMD%"=="" (
    echo   [FAIL]  Python 3.10+ is required but not found.
    echo           Download from https://python.org
    exit /b 1
)

echo   Python:       %PY_VER% (%PYTHON_CMD%)
echo   [OK]    Environment check passed
echo.

REM ── Create Virtual Environment ──────────────────────
if exist "venv\Scripts\activate.bat" (
    echo   [INFO]  Virtual environment already exists
) else (
    echo   [INFO]  Creating virtual environment...
    %PYTHON_CMD% -m venv venv
    if %errorlevel% neq 0 (
        echo   [FAIL]  Failed to create virtual environment
        exit /b 1
    )
    echo   [OK]    Virtual environment created at .\venv
)

REM ── Activate venv ───────────────────────────────────
call venv\Scripts\activate.bat
echo   [OK]    Virtual environment activated

REM ── Upgrade pip ─────────────────────────────────────
echo   [INFO]  Upgrading pip...
pip install --upgrade pip --quiet
echo   [OK]    pip upgraded

REM ── Install Dependencies ────────────────────────────
if not exist "requirements.txt" (
    echo   [FAIL]  requirements.txt not found
    exit /b 1
)

echo   [INFO]  Installing dependencies (this may take a few minutes)...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo   [FAIL]  Dependency installation failed
    exit /b 1
)
echo   [OK]    All dependencies installed

REM ── Post-Install Setup ─────────────────────────────
if not exist ".env" (
    if exist ".env.example" (
        copy .env.example .env >nul
        echo   [OK]    Created .env from .env.example
    ) else (
        (
            echo # ANA Environment Configuration
            echo API_BASE=http://localhost:9000
            echo # GEMINI_API_KEY=your_key_here
            echo # MISTRAL_API_URL=http://localhost:11434/api/generate
        ) > .env
        echo   [OK]    Created default .env
    )
    echo   [WARN]  Edit .env to set your API keys ^(optional for AI features^)
)

if not exist "db" mkdir db

REM ── Verify Installation ─────────────────────────────
echo.
echo   [INFO]  Verifying installation...
for %%p in (streamlit fastapi uvicorn pandas plotly bcrypt networkx pydantic requests) do (
    python -c "import %%p" >nul 2>&1
    if !errorlevel! equ 0 (
        echo     %%p ... OK
    ) else (
        echo     %%p ... MISSING
    )
)
echo   [OK]    Verification complete

REM ── Summary ─────────────────────────────────────────
echo.
echo   ============================================================
echo            Installation Complete! (Source)
echo   ============================================================
echo.
echo   Start the application:
echo     scripts\start.bat
echo.
echo   Or manually:
echo     venv\Scripts\activate
echo     start cmd /k "python -m uvicorn backend.main:app --port 9000 --reload"
echo     python -m streamlit run app.py
echo.
echo   Access:
echo     Frontend:  http://localhost:8501
echo     API Docs:  http://localhost:9000/docs
echo.
echo   Default Logins:
echo     admin / admin123        (Full access)
echo     operator1 / operator123  (Operator)
echo     approver1 / approver123  (Approver)
echo     demo / demo              (Read-only demo)
echo.
echo   Optional: Set GEMINI_API_KEY in .env for AI features
echo.

endlocal
