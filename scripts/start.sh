#!/usr/bin/env bash
# ============================================================
# ANA - Agentic Network Assistant
# Start Script for Linux / macOS
# ============================================================
# Auto-detects whether to run via Docker or source:
#   - Source found  → runs Python processes (private/dev repo)
#   - Source missing → runs Docker container (public repo)
#
# Usage:
#   ./scripts/start.sh             # Start (auto-detect mode)
#   ./scripts/start.sh --backend   # Start only backend (source mode)
#   ./scripts/start.sh --frontend  # Start only frontend (source mode)
#   ./scripts/start.sh --stop      # Stop all ANA processes
# ============================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────
DOCKER_IMAGE="ghcr.io/tuhinbhaumik/ana"
DOCKER_TAG="latest"
CONTAINER_NAME="ana"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

BACKEND_PORT="${ANA_BACKEND_PORT:-9000}"
FRONTEND_PORT="${ANA_FRONTEND_PORT:-8501}"

# ── Detect mode ───────────────────────────────────────
HAS_SOURCE=false
if [ -f "app.py" ] && [ -f "backend/main.py" ]; then
    HAS_SOURCE=true
fi

HAS_DOCKER=false
if command -v docker &>/dev/null; then
    HAS_DOCKER=true
fi

# ── Stop command (handles both modes) ─────────────────
stop_services() {
    echo -e "${CYAN}Stopping ANA services...${NC}"

    # Stop Docker container if running
    if [ "$HAS_DOCKER" = true ]; then
        docker stop "$CONTAINER_NAME" 2>/dev/null && docker rm "$CONTAINER_NAME" 2>/dev/null \
            && echo "  Docker container stopped" || true
    fi

    # Stop source processes
    pkill -f "uvicorn backend.main:app" 2>/dev/null && echo "  Backend stopped" || true
    pkill -f "streamlit run app.py" 2>/dev/null && echo "  Frontend stopped" || true

    echo "  Done."
    exit 0
}

# ── Parse arguments ───────────────────────────────────
START_BACKEND=true
START_FRONTEND=true

case "${1:-all}" in
    --backend)  START_FRONTEND=false ;;
    --frontend) START_BACKEND=false ;;
    --stop)     stop_services ;;
    all|"")     ;; # start both
    *)
        echo "Usage: $0 [--backend|--frontend|--stop]"
        exit 1
        ;;
esac

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║       ANA - Agentic Network Assistant             ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ══════════════════════════════════════════════════════
# ── DOCKER MODE (no source code) ─────────────────────
# ══════════════════════════════════════════════════════
if [ "$HAS_SOURCE" = false ]; then

    if [ "$HAS_DOCKER" != true ]; then
        echo -e "${RED}  No source code found and Docker not installed.${NC}"
        echo "  Run ./scripts/install.sh first, or install Docker."
        exit 1
    fi

    echo -e "${CYAN}  Mode: Docker container${NC}"
    echo ""

    # Check if already running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}  ANA container is already running!${NC}"
        echo "    Frontend:  http://localhost:${FRONTEND_PORT}"
        echo "    API Docs:  http://localhost:${BACKEND_PORT}/docs"
        echo ""
        echo -e "${YELLOW}  Stop with: ./scripts/start.sh --stop${NC}"
        exit 0
    fi

    # Remove stopped container if exists
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    # Build docker run command
    DOCKER_RUN_CMD="docker run -d --name ${CONTAINER_NAME}"
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -p ${FRONTEND_PORT}:8501 -p ${BACKEND_PORT}:9000"
    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} -v ana-data:/app/db"

    # Pass .env file if it exists
    if [ -f ".env" ]; then
        DOCKER_RUN_CMD="${DOCKER_RUN_CMD} --env-file .env"
    fi

    DOCKER_RUN_CMD="${DOCKER_RUN_CMD} ${DOCKER_IMAGE}:${DOCKER_TAG}"

    echo -e "${CYAN}  Starting ANA container...${NC}"
    eval "$DOCKER_RUN_CMD"

    # Wait for container to be healthy
    echo -n "  Waiting for services"
    for i in $(seq 1 30); do
        if curl -s "http://localhost:${BACKEND_PORT}/api/health" >/dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}  ANA is running! (Docker)${NC}"
            echo ""
            echo "    Frontend:  http://localhost:${FRONTEND_PORT}"
            echo "    API Docs:  http://localhost:${BACKEND_PORT}/docs"
            echo ""
            echo -e "${YELLOW}  View logs:  docker logs -f ${CONTAINER_NAME}"
            echo -e "  Stop:       ./scripts/start.sh --stop${NC}"
            echo ""
            exit 0
        fi
        echo -n "."
        sleep 1
    done

    echo ""
    echo -e "${YELLOW}  Container started but health check pending."
    echo "  Check logs: docker logs ${CONTAINER_NAME}${NC}"
    exit 0
fi

# ══════════════════════════════════════════════════════
# ── SOURCE MODE (app.py found) ───────────────────────
# ══════════════════════════════════════════════════════
echo -e "${CYAN}  Mode: Source (Python)${NC}"
echo ""

# ── Activate venv ─────────────────────────────────────
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "env/bin/activate" ]; then
    source env/bin/activate
else
    echo -e "${YELLOW}WARNING: No virtual environment found. Using system Python.${NC}"
fi

# ── Start Backend ─────────────────────────────────────
if [ "$START_BACKEND" = true ]; then
    echo -e "${CYAN}Starting backend on port $BACKEND_PORT...${NC}"
    python -m uvicorn backend.main:app \
        --host 0.0.0.0 \
        --port "$BACKEND_PORT" \
        --reload &
    BACKEND_PID=$!
    echo -e "${GREEN}  Backend PID: $BACKEND_PID${NC}"

    echo -n "  Waiting for backend"
    for i in $(seq 1 30); do
        if curl -s "http://localhost:$BACKEND_PORT/api/health" >/dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}  Backend ready at http://localhost:$BACKEND_PORT${NC}"
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
fi

# ── Start Frontend ────────────────────────────────────
if [ "$START_FRONTEND" = true ]; then
    echo -e "${CYAN}Starting frontend on port $FRONTEND_PORT...${NC}"
    python -m streamlit run app.py \
        --server.port "$FRONTEND_PORT" \
        --server.address 0.0.0.0 &
    FRONTEND_PID=$!
    echo -e "${GREEN}  Frontend PID: $FRONTEND_PID${NC}"
fi

# ── Summary ───────────────────────────────────────────
echo ""
echo -e "${GREEN}  ANA is running! (Source)${NC}"
echo ""
if [ "$START_BACKEND" = true ]; then
    echo "    Backend:   http://localhost:$BACKEND_PORT"
    echo "    API Docs:  http://localhost:$BACKEND_PORT/docs"
fi
if [ "$START_FRONTEND" = true ]; then
    echo "    Frontend:  http://localhost:$FRONTEND_PORT"
fi
echo ""
echo -e "${YELLOW}  Press Ctrl+C to stop, or run: ./scripts/start.sh --stop${NC}"
echo ""

wait
