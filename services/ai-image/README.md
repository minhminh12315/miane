# MIANE AI Image Service

FastAPI service for generating and caching destination cover images.

## Run

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Endpoint

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

## Local AI Backends

The service is designed for local/free image generation. In development it
ships with a deterministic Pillow fallback so the app always has a cover image.
You can later enable a local Diffusers/SDXL or Flux Schnell backend without
changing the Flutter UI contract.

## AI-OCR (Receipt Scanning)

Receipt OCR runs **on-device** in the Flutter app (native text recognizer +
a rule-based Vietnamese parser) — there is no backend endpoint for this
feature. See [AI_OCR_LOCAL_REQUIREMENTS.md](../../AI_OCR_LOCAL_REQUIREMENTS.md)
at the repo root for the spec, and
`src/Clients/mobile/lib/features/expense/domain/services/vn_receipt_parser.dart`
for the implementation.

