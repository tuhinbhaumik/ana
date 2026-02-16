# ANA Installation Guide

<p align="center">
  <strong>Agentic Network Assistant</strong><br>
  <em>Enterprise-Grade Autonomous Network Operations Platform</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.10+-blue?logo=python&logoColor=white" alt="Python 3.10+">
  <img src="https://img.shields.io/badge/Docker-Supported-2496ED?logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Windows-Supported-0078D6?logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Linux-Supported-FCC624?logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/macOS-Supported-000000?logo=apple&logoColor=white" alt="macOS">
</p>

---

## Table of Contents

- [Quick Start (60 Seconds)](#quick-start-60-seconds)
- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
  - [Method 1: Automated Script (Recommended)](#method-1-automated-script-recommended)
  - [Method 2: Docker (Zero Dependencies)](#method-2-docker-zero-dependencies)
  - [Method 3: Docker Compose](#method-3-docker-compose)
  - [Method 4: Manual Installation](#method-4-manual-installation)
  - [Method 5: Python Setup Script](#method-5-python-setup-script)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [AI Assistant Setup (Optional)](#ai-assistant-setup-optional)
- [Starting the Application](#starting-the-application)
- [Verifying the Installation](#verifying-the-installation)
- [Default User Accounts](#default-user-accounts)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)
- [Platform-Specific Notes](#platform-specific-notes)

---

> **How the scripts work:** All install and start scripts **auto-detect** your environment.
> If source code is present (private repo clone), they use Python/venv.
> If source code is absent (public repo clone), they pull and run the pre-built Docker image from GHCR.
> You can also force a mode: `--docker` or `--source`.

---

## Quick Start (60 Seconds)

### Public Repo Users (Docker - no source code needed)

```bash
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA
chmod +x scripts/install.sh scripts/start.sh   # Linux/macOS only
./scripts/install.sh    # auto-detects Docker, pulls image from GHCR
./scripts/start.sh      # runs the container
```

**Windows:**
```powershell
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA
scripts\install.bat     & REM auto-detects Docker, pulls image
scripts\start.bat       & REM runs the container
```

### Private Repo / Developers (full source)

**Linux / macOS:**
```bash
git clone https://github.com/tuhinbhaumik/ANA-private.git ANA
cd ANA
chmod +x scripts/install.sh scripts/start.sh
./scripts/install.sh    # auto-detects source, creates venv, installs deps
./scripts/start.sh      # starts Python backend + frontend
```

**Windows:**
```powershell
git clone https://github.com/tuhinbhaumik/ANA-private.git ANA
cd ANA
scripts\install.bat
scripts\start.bat
```

**Docker Compose (from source):**
```bash
cd ANA
docker compose up -d
```

Then open **http://localhost:8501** and log in with `admin` / `admin123`.

---

## Prerequisites

### Required

| Requirement | Version   | Check Command          | Notes                                   |
|-------------|-----------|------------------------|-----------------------------------------|
| **Python**  | 3.10 - 3.13 | `python --version`   | Python 3.12 recommended                |
| **pip**     | 21.0+     | `pip --version`        | Usually bundled with Python             |
| **Git**     | Any       | `git --version`        | For cloning the repository              |

### Optional

| Requirement    | Version | Purpose                              |
|----------------|---------|--------------------------------------|
| **Docker**     | 20.10+  | Containerized deployment             |
| **Docker Compose** | 2.0+ | Multi-service orchestration       |
| **Gemini API Key** | --  | AI-powered assistant features       |
| **Ollama**     | Latest  | Local LLM fallback (Mistral model)  |

### System Requirements

| Resource  | Minimum | Recommended |
|-----------|---------|-------------|
| CPU       | 2 cores | 4 cores     |
| RAM       | 2 GB    | 4 GB        |
| Disk      | 500 MB  | 1 GB        |
| Ports     | 8501, 9000 | 8501, 9000 |

---

## Installation Methods

### Method 1: Automated Script (Recommended)

The install scripts **auto-detect** your environment and choose the right install path:

| Condition | Mode | What happens |
|-----------|------|-------------|
| Source code present (`app.py` found) | **Source** | Creates venv, installs Python deps |
| Source code absent + Docker installed | **Docker** | Pulls pre-built image from GHCR |
| Neither | Error | Tells you what to install |

You can also force a mode with `--docker` or `--source`.

#### Linux / macOS

```bash
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA
chmod +x scripts/install.sh scripts/start.sh

./scripts/install.sh              # Auto-detect
# or: ./scripts/install.sh --docker   # Force Docker
# or: ./scripts/install.sh --source   # Force source
```

#### Windows

```powershell
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA

scripts\install.bat               & REM Auto-detect
REM or: scripts\install.bat --docker   Force Docker
REM or: scripts\install.bat --source   Force source
```

**What the installer does (Source mode):**
1. Detects your OS, architecture, and Python version
2. Validates Python 3.10+ is available
3. Creates an isolated virtual environment (`venv/`)
4. Upgrades pip to the latest version
5. Installs all dependencies from `requirements.txt`
6. Creates a `.env` file from the template
7. Verifies all core packages are importable
8. Prints next steps and access URLs

**What the installer does (Docker mode):**
1. Detects Docker is available
2. Pulls `ghcr.io/tuhinbhaumik/ana:latest`
3. Creates a `.env` file from the template
4. Prints Docker run command and access URLs

---

### Method 2: Docker (Zero Dependencies)

Run ANA in a container without installing Python or any dependencies on your host machine.

```bash
# Clone and build
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA
docker build -t ana .

# Run the container
docker run -d \
  --name ana \
  -p 8501:8501 \
  -p 9000:9000 \
  -v ana-data:/app/db \
  ana
```

**Or pull a pre-built image (when available from GitHub Releases):**

```bash
docker pull ghcr.io/tuhinbhaumik/ana:latest
docker run -d \
  --name ana \
  -p 8501:8501 \
  -p 9000:9000 \
  ghcr.io/tuhinbhaumik/ana:latest
```

**With AI features enabled:**
```bash
docker run -d \
  --name ana \
  -p 8501:8501 \
  -p 9000:9000 \
  -e GEMINI_API_KEY=your_api_key_here \
  -v ana-data:/app/db \
  ana
```

**Container management:**
```bash
docker logs -f ana          # View live logs
docker stop ana             # Stop the container
docker start ana            # Restart the container
docker rm -f ana            # Remove the container
```

---

### Method 3: Docker Compose

The simplest approach for persistent deployment with data volumes.

```bash
# Clone the repository
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA

# (Optional) Configure environment
cp .env.example .env
# Edit .env to set GEMINI_API_KEY, custom ports, etc.

# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Rebuild after code changes
docker compose up -d --build
```

**Custom port mapping (via `.env`):**
```env
ANA_FRONTEND_PORT=3000
ANA_BACKEND_PORT=8000
```

---

### Method 4: Manual Installation

Full control over every step. Recommended for development or customization.

#### Step 1: Clone the Repository

```bash
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA
```

#### Step 2: Create a Virtual Environment

**Linux / macOS:**
```bash
python3 -m venv venv
source venv/bin/activate
```

**Windows:**
```powershell
python -m venv venv
venv\Scripts\activate
```

#### Step 3: Upgrade pip

```bash
pip install --upgrade pip
```

#### Step 4: Install Dependencies

```bash
pip install -r requirements.txt
```

This installs the following core packages and their transitive dependencies:

| Package           | Purpose                                    |
|-------------------|--------------------------------------------|
| `streamlit`       | Web UI framework (frontend)                |
| `fastapi`         | REST API framework (backend)               |
| `uvicorn[standard]` | ASGI server for FastAPI                  |
| `pandas`          | Data manipulation and table rendering      |
| `plotly`          | Interactive charts and topology graphs     |
| `bcrypt`          | Password hashing for authentication        |
| `pydantic`        | Data validation and API models             |
| `requests`        | HTTP client for frontend-to-backend calls  |
| `python-dotenv`   | Environment variable management            |
| `networkx`        | Network topology graph algorithms          |
| `google-genai`    | Google Gemini AI integration               |

#### Step 5: Configure Environment

```bash
# Copy the template
cp .env.example .env     # Linux/macOS
copy .env.example .env   # Windows

# Edit .env as needed (all settings are optional with sensible defaults)
```

#### Step 6: Start the Application

Open two terminal windows:

**Terminal 1 - Backend:**
```bash
source venv/bin/activate            # Linux/macOS
# venv\Scripts\activate             # Windows
python -m uvicorn backend.main:app --host 0.0.0.0 --port 9000 --reload
```

**Terminal 2 - Frontend:**
```bash
source venv/bin/activate            # Linux/macOS
# venv\Scripts\activate             # Windows
python -m streamlit run app.py
```

---

### Method 5: Python Setup Script

A cross-platform Python installer with full environment detection.

```bash
git clone https://github.com/tuhinbhaumik/ANA.git
cd ANA
python setup.py
```

This script:
- Detects OS, architecture, Python version, and pip availability
- Displays a detailed environment report
- Creates and configures a virtual environment
- Installs all dependencies
- Runs post-install setup (`.env`, directories, Streamlit config)
- Prints a summary with start commands

---

## Configuration

### Environment Variables

All configuration is done through the `.env` file. Copy the template:

```bash
cp .env.example .env
```

| Variable            | Default                                    | Description                                |
|---------------------|--------------------------------------------|--------------------------------------------|
| `API_BASE`          | `http://localhost:9000`                    | Backend API URL (used by frontend)         |
| `GEMINI_API_KEY`    | *(empty)*                                  | Google Gemini API key for AI features      |
| `MISTRAL_API_URL`   | `http://localhost:11434/api/generate`      | Ollama/Mistral local LLM endpoint          |
| `ANA_FRONTEND_PORT` | `8501`                                     | Streamlit port (Docker Compose only)       |
| `ANA_BACKEND_PORT`  | `9000`                                     | FastAPI port (Docker Compose only)         |

### AI Assistant Setup (Optional)

ANA's AI Assistant supports three modes in a fallback chain:

#### Option A: Google Gemini (Primary - Recommended)

1. Get a free API key at [Google AI Studio](https://aistudio.google.com/apikey)
2. Add to `.env`:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```

#### Option B: Ollama + Mistral (Offline Fallback)

1. Install Ollama from [ollama.com](https://ollama.com)
2. Pull the Mistral model:
   ```bash
   ollama pull mistral
   ```
3. Ollama runs automatically on `localhost:11434`

#### Option C: Built-in Query Engine (Always Available)

If no LLM is configured, ANA falls back to a built-in query engine that provides structured responses from live operational data. No setup required.

---

## Starting the Application

### Using Start Scripts

**Linux / macOS:**
```bash
./scripts/start.sh              # Start both services
./scripts/start.sh --backend    # Backend only
./scripts/start.sh --frontend   # Frontend only
./scripts/start.sh --stop       # Stop all services
```

**Windows:**
```powershell
scripts\start.bat               # Start both services
scripts\start.bat --backend     # Backend only
scripts\start.bat --frontend    # Frontend only
scripts\start.bat --stop        # Stop all services
```

### Using Docker

```bash
docker compose up -d            # Start
docker compose down             # Stop
docker compose restart          # Restart
docker compose logs -f          # View logs
```

---

## Verifying the Installation

After starting, verify all components are working:

### 1. Backend Health Check

```bash
curl http://localhost:9000/api/health
# Expected: {"status": "healthy"}
```

### 2. API Documentation

Open http://localhost:9000/docs in your browser. You should see the interactive Swagger UI with all API endpoints.

### 3. Frontend

Open http://localhost:8501 in your browser. You should see the ANA login page.

### 4. Package Verification

```bash
# Activate venv first, then:
python -c "
import streamlit, fastapi, uvicorn, pandas, plotly, bcrypt
import pydantic, requests, networkx
print('All core packages verified successfully!')
"
```

---

## Default User Accounts

The database is automatically initialized with seed data on first startup.

| Username    | Password      | Role      | Access                                  |
|-------------|---------------|-----------|----------------------------------------|
| `admin`     | `admin123`    | admin     | Full access to all pages and features  |
| `operator1` | `operator123` | operator  | Incidents, Problems, Capacity, ChatOps |
| `approver1` | `approver123` | approver  | Change management approval workflows   |
| `demo`      | `demo`        | demo      | Read-only access to all pages (simulated data, no writes) |

> **Note:** The `demo` account is ideal for exploring the platform without affecting data.

---

## Upgrading

### From Git

```bash
cd ANA
git pull origin main

# Re-install dependencies (in case of updates)
source venv/bin/activate          # Linux/macOS
# venv\Scripts\activate           # Windows
pip install -r requirements.txt

# Restart services
./scripts/start.sh --stop && ./scripts/start.sh
```

### Docker

```bash
cd ANA
git pull origin main
docker compose up -d --build
```

### Database Migrations

ANA uses SQLite with automatic schema initialization. If the schema changes between versions:

```bash
# Back up existing data
cp db/ana.db db/ana.db.backup

# Delete old database (will be recreated on next startup)
rm db/ana.db

# Restart - fresh database with updated schema and seed data
./scripts/start.sh
```

---

## Uninstalling

### Native Installation

```bash
# Stop services
./scripts/start.sh --stop       # Linux/macOS
scripts\start.bat --stop        # Windows

# Remove virtual environment and data
rm -rf venv/ db/ana.db .env     # Linux/macOS
rmdir /s /q venv                # Windows
del db\ana.db .env              # Windows

# Remove the project directory
cd ..
rm -rf ANA/                     # Linux/macOS
rmdir /s /q ANA                 # Windows
```

### Docker

```bash
docker compose down -v          # Stop and remove volumes
docker rmi ana                  # Remove the image
```

---

## Troubleshooting

### Common Issues

<details>
<summary><strong>Port already in use (Address already in use / WinError 10048)</strong></summary>

Another process is using port 8501 or 9000.

**Linux / macOS:**
```bash
lsof -i :9000
kill -9 <PID>
```

**Windows:**
```powershell
netstat -ano | findstr :9000
taskkill /PID <PID> /F
```
</details>

<details>
<summary><strong>ModuleNotFoundError: No module named 'xxx'</strong></summary>

A dependency is missing. Ensure your virtual environment is activated and reinstall:

```bash
source venv/bin/activate        # Linux/macOS
# venv\Scripts\activate         # Windows
pip install -r requirements.txt
```
</details>

<details>
<summary><strong>Backend API unavailable (Connection refused)</strong></summary>

The FastAPI backend isn't running or hasn't started yet.

1. Check if the backend is running:
   ```bash
   curl http://localhost:9000/api/health
   ```
2. Start it manually:
   ```bash
   python -m uvicorn backend.main:app --port 9000 --reload
   ```
3. Check for errors in the backend terminal output
</details>

<details>
<summary><strong>Database locked (SQLite)</strong></summary>

Multiple processes are trying to write to the database simultaneously.

1. Stop all ANA processes
2. Delete the WAL files:
   ```bash
   rm -f db/ana.db-wal db/ana.db-shm
   ```
3. Restart the application
</details>

<details>
<summary><strong>Docker: Permission denied</strong></summary>

Add your user to the Docker group:
```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```
</details>

<details>
<summary><strong>Python version too old</strong></summary>

ANA requires Python 3.10 or newer.

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install python3.12 python3.12-venv
```

**macOS:**
```bash
brew install python@3.12
```

**Windows:**
Download from [python.org](https://python.org/downloads/)
</details>

<details>
<summary><strong>pip install fails with compilation errors</strong></summary>

Some packages (like `bcrypt`) require C compilation. Install build tools:

**Ubuntu/Debian:**
```bash
sudo apt install build-essential python3-dev
```

**macOS:**
```bash
xcode-select --install
```

**Windows:**
Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
</details>

<details>
<summary><strong>Streamlit theme not loading</strong></summary>

Ensure the `.streamlit/config.toml` file exists. The installer creates it automatically. To recreate manually:

```bash
mkdir -p .streamlit
cat > .streamlit/config.toml << 'EOF'
[theme]
primaryColor = "#0D47A1"
backgroundColor = "#FFFFFF"
secondaryBackgroundColor = "#E8EAF6"
textColor = "#0D1B2A"
font = "sans serif"

[server]
headless = true

[browser]
gatherUsageStats = false
EOF
```
</details>

---

## Platform-Specific Notes

### Windows

- Use `venv\Scripts\activate` (backslashes) to activate the virtual environment
- The start script opens backend and frontend in separate CMD windows
- If `python` is not recognized, add Python to your PATH during installation
- PowerShell users may need to run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` first

### macOS

- If using Homebrew Python, ensure `python3` points to 3.10+: `python3 --version`
- On Apple Silicon (M1/M2/M3), all dependencies are compatible with `arm64`
- You may need to install Xcode Command Line Tools: `xcode-select --install`

### Linux

- Ubuntu/Debian: `sudo apt install python3 python3-pip python3-venv`
- RHEL/CentOS/Fedora: `sudo dnf install python3 python3-pip`
- Alpine (Docker): The Dockerfile uses `python:3.12-slim` (Debian-based)
- SELinux users may need to set appropriate contexts for the database directory

### WSL (Windows Subsystem for Linux)

ANA works in WSL2. Use the Linux installation instructions:
```bash
./scripts/install.sh
./scripts/start.sh
```
Access via `http://localhost:8501` from your Windows browser.

---

## Project Structure (Reference)

```
ANA/
├── app.py                  # Streamlit entry point & routing
├── requirements.txt        # Python dependencies
├── setup.py                # Cross-platform installer with env detection
├── Dockerfile              # Multi-stage container build
├── docker-compose.yml      # Docker orchestration
├── .env.example            # Environment variable template
├── .gitignore              # Git exclusions
├── .dockerignore           # Docker build exclusions
├── LICENSE                 # MIT License
├── README.md               # Project overview & features
├── INSTALL.md              # This installation guide
│
├── scripts/
│   ├── install.sh          # Linux/macOS automated installer
│   ├── install.bat         # Windows automated installer
│   ├── start.sh            # Linux/macOS start/stop script
│   ├── start.bat           # Windows start/stop script
│   └── entrypoint.sh       # Docker container entrypoint
│
├── auth/                   # Authentication & session management
├── backend/                # FastAPI REST API
├── db/                     # SQLite database (auto-created)
├── mcp/                    # API client layer
├── views/                  # Streamlit UI pages
├── .streamlit/             # Streamlit theme & config
├── .github/workflows/      # CI/CD pipeline
└── docs/                   # Design & build documentation
```

---

## Need Help?

- Check the [Troubleshooting](#troubleshooting) section above
- Review API docs at http://localhost:9000/docs
- Open an issue on [GitHub](https://github.com/tuhinbhaumik/ANA/issues)

---

<p align="center">
  <strong>ANA - Agentic Network Assistant</strong><br>
  <em>Built for enterprise network operations teams</em><br>
  MIT License &copy; 2026 Tuhin Bhaumik
</p>
