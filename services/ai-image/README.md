# MIANE AI Image Service

FastAPI service for generating and caching destination cover images.

## Run

```bash
pip install -r requirements.txt
export OPENAI_API_KEY="sk-..."
uvicorn app.main:app --reload --port 8000
```

On Windows PowerShell:

```powershell
$env:OPENAI_API_KEY="sk-..."
uvicorn app.main:app --reload --port 8000
```

## Endpoints

### Trip thumbnail

`POST /api/v1/image/generate-trip-thumbnail`

```json
{
  "placeId": "ChIJP3Sa8ziYEmsRUKgyFmh9AQM",
  "placeName": "Da Lat",
  "formattedAddress": "Da Lat, Lam Dong, Vietnam",
  "latitude": 11.9404,
  "longitude": 108.4583,
  "city": "Da Lat",
  "province": "Lam Dong",
  "country": "Vietnam"
}
```

Response:

```json
{
  "imageUrl": "http://localhost:8000/static/cache/<hash>.jpg",
  "prompt": "Create an ultra realistic travel destination photo...",
  "landmark": "Xuan Huong Lake",
  "cached": true
}
```

The service caches by `placeId` when available, otherwise by place name and
coordinates. It asks Ollama to choose a real landmark when available, then uses
OpenAI Image API to generate a real destination cover. If `OPENAI_API_KEY` is
missing, the endpoint returns a configuration error instead of creating an
unrelated placeholder image.

### Legacy cover endpoint

`POST /api/generate-trip-image`

```json
{
  "destination": "Da Nang, Vietnam"
}
```

Response:

```json
{
  "imageUrl": "http://localhost:8000/static/cache/<hash>.png",
  "cached": true
}
```

## Image backend

OpenAI generation is configured with:

- `OPENAI_API_KEY`
- `OPENAI_IMAGE_MODEL=gpt-image-1.5`
- `OPENAI_IMAGE_SIZE=1536x1024`
- `OPENAI_IMAGE_QUALITY=high`
- `OPENAI_IMAGE_FORMAT=jpeg`

Optional landmark selection:

- `AI_IMAGE_USE_OLLAMA=true`
- `OLLAMA_BASE_URL=http://localhost:11434`
- `AI_IMAGE_LANDMARK_MODEL=llama3.2:3b`
