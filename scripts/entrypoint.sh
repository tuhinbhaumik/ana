#!/usr/bin/env bash
# ============================================================
# ANA Docker Container Entrypoint
# Starts both FastAPI backend and Streamlit frontend
# Reads ports from ANA_BACKEND_PORT / ANA_FRONTEND_PORT env vars
# ============================================================

set -e

BACKEND_PORT="${ANA_BACKEND_PORT:-9000}"
FRONTEND_PORT="${ANA_FRONTEND_PORT:-8501}"

# Export API_BASE so the frontend can reach the backend
export API_BASE="http://localhost:${BACKEND_PORT}"

echo "============================================"
echo "  ANA - Agentic Network Assistant"
echo "  Starting services..."
echo "  Backend port:  ${BACKEND_PORT}"
echo "  Frontend port: ${FRONTEND_PORT}"
echo "============================================"

# Start FastAPI backend in background
echo "[1/2] Starting backend on port ${BACKEND_PORT}..."
python -m uvicorn backend.main:app \
    --host 0.0.0.0 \
    --port "${BACKEND_PORT}" &
BACKEND_PID=$!

# Wait for backend to be ready
echo "      Waiting for backend..."
for i in $(seq 1 30); do
    if python -c "import requests; requests.get('http://localhost:${BACKEND_PORT}/api/health')" 2>/dev/null; then
        echo "      Backend ready!"
        break
    fi
    sleep 1
done

# Start Streamlit frontend in foreground
echo "[2/2] Starting frontend on port ${FRONTEND_PORT}..."
echo "============================================"
echo "  Frontend:  http://localhost:${FRONTEND_PORT}"
echo "  API Docs:  http://localhost:${BACKEND_PORT}/docs"
echo "============================================"

exec python -m streamlit run app.py \
    --server.port "${FRONTEND_PORT}" \
    --server.address 0.0.0.0 \
    --server.headless true
