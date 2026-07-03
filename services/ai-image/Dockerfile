FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000
ENV AI_IMAGE_CACHE_DIR=/app/cache

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

