# ============================================================
# ANA - Agentic Network Assistant
# Multi-stage Docker Build
# ============================================================
# Usage:
#   docker build -t ana .
#   docker run -d -p 8501:8501 -p 9000:9000 --name ana ana
# ============================================================

# ── Stage 1: Builder ──────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────────
FROM python:3.12-slim AS runtime

LABEL maintainer="Tuhin Bhaumik"
LABEL org.opencontainers.image.title="ANA - Agentic Network Assistant"
LABEL org.opencontainers.image.description="Enterprise-Grade Autonomous Network Operations Platform"
LABEL org.opencontainers.image.source="https://github.com/tuhinbhaumik/ANA"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app.py .
COPY requirements.txt .
COPY .env.example .
COPY auth/ auth/
COPY backend/ backend/
COPY db/ db/
COPY mcp/ mcp/
COPY views/ views/
COPY scripts/ scripts/
COPY .streamlit/ .streamlit/

# Create writable directories
RUN mkdir -p /app/db && chmod 777 /app/db

# Environment variables with sensible defaults
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    API_BASE=http://localhost:9000 \
    STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

# Expose ports: Streamlit (8501) + FastAPI (9000)
EXPOSE 8501 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:9000/api/health')" || exit 1

# Make entrypoint executable and start services
RUN chmod +x /app/scripts/entrypoint.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
