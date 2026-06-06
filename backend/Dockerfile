FROM python:3.11-slim

RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# /data is for the persistent disk (Render paid plan).
# /app is owned by app so the default SQLite file is writable on free tier too.
RUN mkdir -p /data && chown -R app:app /app /data

USER app

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-10000}"]
