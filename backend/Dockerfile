FROM python:3.11-slim

# Security: run as non-root
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Install deps first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Create data directory for SQLite persistent disk (Render mounts /data)
RUN mkdir -p /data && chown app:app /data

USER app

# Render sets $PORT (defaults to 10000); bind to 0.0.0.0 so the container is reachable
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-10000}"]
