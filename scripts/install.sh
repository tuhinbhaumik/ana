#!/usr/bin/env bash
# ============================================================
# ANA - Agentic Network Assistant
# Automated Installer for Linux / macOS
# ============================================================
# Auto-detects whether source code is present:
#   - Source found  → Python venv install (private/dev repo)
#   - Source missing → Docker pull from GHCR (public repo)
#
# Usage:
#   chmod +x scripts/install.sh
#   ./scripts/install.sh              # Auto-detect mode
#   ./scripts/install.sh --docker     # Force Docker mode
#   ./scripts/install.sh --source     # Force source mode
# ============================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────
DOCKER_IMAGE="ghcr.io/tuhinbhaumik/ana"
DOCKER_TAG="latest"
CONTAINER_NAME="ana"

# ── Colors ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }

# ── Banner ────────────────────────────────────────────
echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║       ANA - Agentic Network Assistant             ║"
echo "  ║       Installer for Linux / macOS                 ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Navigate to project root ─────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"
info "Project root: $PROJECT_ROOT"

# ── Detect Environment ────────────────────────────────
info "Detecting environment..."

OS="$(uname -s)"
ARCH="$(uname -m)"
echo "  OS:           $OS $(uname -r)"
echo "  Architecture: $ARCH"

# ── Determine install mode ────────────────────────────
# Auto-detect: if app.py exists → source mode, else → docker mode
INSTALL_MODE="auto"
case "${1:-}" in
    --docker) INSTALL_MODE="docker" ;;
    --source) INSTALL_MODE="source" ;;
    "")       INSTALL_MODE="auto" ;;
    *)        echo "Usage: $0 [--docker|--source]"; exit 1 ;;
esac

HAS_SOURCE=false
if [ -f "app.py" ] && [ -f "backend/main.py" ]; then
    HAS_SOURCE=true
fi

HAS_DOCKER=false
if command -v docker &>/dev/null; then
    HAS_DOCKER=true
fi

# Resolve auto mode
if [ "$INSTALL_MODE" = "auto" ]; then
    if [ "$HAS_SOURCE" = true ]; then
        INSTALL_MODE="source"
    elif [ "$HAS_DOCKER" = true ]; then
        INSTALL_MODE="docker"
    else
        fail "No source code found and Docker not installed.\n         Install Docker (https://docker.com) or use the full source repo."
    fi
fi

echo ""
echo -e "  ${BOLD}Install mode:   ${INSTALL_MODE}${NC}"
echo "  Source code:   $([ "$HAS_SOURCE" = true ] && echo "Found" || echo "Not found")"
echo "  Docker:        $([ "$HAS_DOCKER" = true ] && echo "Available ($(docker --version 2>/dev/null | head -1))" || echo "Not installed")"
echo ""

# ══════════════════════════════════════════════════════
# ── DOCKER INSTALL MODE ──────────────────────────────
# ══════════════════════════════════════════════════════
if [ "$INSTALL_MODE" = "docker" ]; then

    if [ "$HAS_DOCKER" != true ]; then
        fail "Docker is required for this install mode.\n         Install from https://docker.com"
    fi

    info "Pulling ANA Docker image from GHCR..."
    docker pull "${DOCKER_IMAGE}:${DOCKER_TAG}"
    success "Image pulled: ${DOCKER_IMAGE}:${DOCKER_TAG}"

    # Create .env from template if needed
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            success "Created .env from .env.example"
        else
            cat > .env <<'ENVEOF'
# ANA Environment Configuration
# GEMINI_API_KEY=your_key_here
ENVEOF
            success "Created default .env"
        fi
        warn "Edit .env to set your API keys (optional for AI features)"
    fi

    # Print Docker summary
    echo ""
    echo -e "${GREEN}  ╔═══════════════════════════════════════════════════╗"
    echo -e "  ║         Installation Complete! (Docker)            ║"
    echo -e "  ╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}  Start the application:${NC}"
    echo "    ./scripts/start.sh"
    echo ""
    echo "  Or manually:"
    echo "    docker run -d --name ${CONTAINER_NAME} \\"
    echo "      -p 8501:8501 -p 9000:9000 \\"
    echo "      --env-file .env \\"
    echo "      -v ana-data:/app/db \\"
    echo "      ${DOCKER_IMAGE}:${DOCKER_TAG}"
    echo ""
    echo -e "${BOLD}  Access:${NC}"
    echo "    Frontend:  http://localhost:8501"
    echo "    API Docs:  http://localhost:9000/docs"
    echo ""
    echo -e "${BOLD}  Default Logins:${NC}"
    echo "    admin / admin123        (Full access)"
    echo "    operator1 / operator123  (Operator)"
    echo "    approver1 / approver123  (Approver)"
    echo "    demo / demo              (Read-only demo)"
    echo ""
    exit 0
fi

# ══════════════════════════════════════════════════════
# ── SOURCE INSTALL MODE ──────────────────────────────
# ══════════════════════════════════════════════════════

if [ "$HAS_SOURCE" != true ]; then
    fail "Source code not found (missing app.py).\n         Use --docker mode or clone the full source repo."
fi

# Detect Python
PYTHON_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PY_VER=$("$cmd" --version 2>&1 | awk '{print $2}')
        PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
        PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
        if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 10 ]; then
            PYTHON_CMD="$cmd"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    fail "Python 3.10+ is required but not found. Install from https://python.org"
fi

echo "  Python:       $PY_VER ($PYTHON_CMD)"
echo "  Python Path:  $(command -v $PYTHON_CMD)"
success "Environment check passed"
echo ""

# ── Create Virtual Environment ────────────────────────
if [ -d "venv" ]; then
    info "Virtual environment already exists at ./venv"
else
    info "Creating virtual environment..."
    $PYTHON_CMD -m venv venv
    success "Virtual environment created at ./venv"
fi

# Activate venv
source venv/bin/activate
success "Virtual environment activated"

# ── Upgrade pip ───────────────────────────────────────
info "Upgrading pip..."
pip install --upgrade pip --quiet
success "pip upgraded to $(pip --version | awk '{print $2}')"

# ── Install Dependencies ─────────────────────────────
if [ ! -f "requirements.txt" ]; then
    fail "requirements.txt not found in project root"
fi

info "Installing dependencies (this may take a few minutes)..."
pip install -r requirements.txt

PKG_COUNT=$(pip list --format=freeze | wc -l | tr -d ' ')
success "Installed $PKG_COUNT packages"

# ── Post-Install Setup ────────────────────────────────
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        success "Created .env from .env.example"
    else
        cat > .env <<'ENVEOF'
# ANA Environment Configuration
API_BASE=http://localhost:9000
# GEMINI_API_KEY=your_key_here
# MISTRAL_API_URL=http://localhost:11434/api/generate
ENVEOF
        success "Created default .env"
    fi
    warn "Edit .env to set your API keys (optional for AI features)"
fi

mkdir -p db

# ── Verify Installation ──────────────────────────────
info "Verifying installation..."

VERIFY_PASS=true
for pkg in streamlit fastapi uvicorn pandas plotly bcrypt networkx pydantic requests; do
    if python -c "import $pkg" 2>/dev/null; then
        echo "    $pkg ... OK"
    else
        echo "    $pkg ... MISSING"
        VERIFY_PASS=false
    fi
done

if [ "$VERIFY_PASS" = true ]; then
    success "All core packages verified"
else
    warn "Some packages may need manual installation"
fi

# ── Print Summary ─────────────────────────────────────
echo ""
echo -e "${GREEN}  ╔═══════════════════════════════════════════════════╗"
echo -e "  ║         Installation Complete! (Source)            ║"
echo -e "  ╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}  Start the application:${NC}"
echo "    ./scripts/start.sh"
echo ""
echo "  Or manually:"
echo "    source venv/bin/activate"
echo "    python -m uvicorn backend.main:app --port 9000 --reload &"
echo "    python -m streamlit run app.py"
echo ""
echo -e "${BOLD}  Access:${NC}"
echo "    Frontend:  http://localhost:8501"
echo "    API Docs:  http://localhost:9000/docs"
echo ""
echo -e "${BOLD}  Default Logins:${NC}"
echo "    admin / admin123        (Full access)"
echo "    operator1 / operator123  (Operator)"
echo "    approver1 / approver123  (Approver)"
echo "    demo / demo              (Read-only demo)"
echo ""
echo -e "${YELLOW}  Optional: Set GEMINI_API_KEY in .env for AI features${NC}"
echo ""
