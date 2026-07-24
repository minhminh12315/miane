from __future__ import annotations

import base64
import hashlib
import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field


CACHE_DIR = Path(os.getenv("AI_IMAGE_CACHE_DIR", "cache")).resolve()
PUBLIC_BASE_URL = os.getenv("AI_IMAGE_PUBLIC_BASE_URL", "http://localhost:8000")
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("AI_IMAGE_LANDMARK_MODEL", "llama3.2:3b")
OPENAI_IMAGE_MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-1.5")
OPENAI_IMAGE_SIZE = os.getenv("OPENAI_IMAGE_SIZE", "1536x1024")
OPENAI_IMAGE_QUALITY = os.getenv("OPENAI_IMAGE_QUALITY", "medium")
OPENAI_IMAGE_FORMAT = os.getenv("OPENAI_IMAGE_FORMAT", "jpeg")
TRIP_API_COVER_PROMPT_MAX_LENGTH = 1000
CACHE_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="MIANE AI Image Service", version="0.2.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/static/cache", StaticFiles(directory=str(CACHE_DIR)), name="cache")


class GenerateTripImageRequest(BaseModel):
    destination: str = Field(min_length=2, max_length=160)


class GenerateTripImageResponse(BaseModel):
    imageUrl: str
    cached: bool


class GenerateTripThumbnailRequest(BaseModel):
    placeId: str | None = Field(default=None, max_length=256)
    placeName: str = Field(min_length=2, max_length=220)
    formattedAddress: str | None = Field(default=None, max_length=500)
    latitude: float | None = None
    longitude: float | None = None
    city: str | None = Field(default=None, max_length=160)
    province: str | None = Field(default=None, max_length=160)
    country: str | None = Field(default=None, max_length=120)


class GenerateTripThumbnailResponse(BaseModel):
    imageUrl: str
    prompt: str
    landmark: str
    cached: bool


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/generate-trip-image", response_model=GenerateTripImageResponse)
def generate_trip_image(
    request: GenerateTripImageRequest,
) -> GenerateTripImageResponse:
    thumbnail = generate_trip_thumbnail(
        GenerateTripThumbnailRequest(placeName=request.destination),
    )
    return GenerateTripImageResponse(
        imageUrl=thumbnail.imageUrl,
        cached=thumbnail.cached,
    )


@app.post(
    "/api/v1/image/generate-trip-thumbnail",
    response_model=GenerateTripThumbnailResponse,
)
def generate_trip_thumbnail(
    request: GenerateTripThumbnailRequest,
) -> GenerateTripThumbnailResponse:
    place_name = _normalize_text(request.placeName)
    if not place_name:
        raise HTTPException(status_code=400, detail="placeName is required")

    cache_key = _cache_key(request)
    image_path = CACHE_DIR / f"{cache_key}.{_image_extension()}"
    meta_path = CACHE_DIR / f"{cache_key}.json"

    if image_path.exists() and meta_path.exists():
        metadata = _read_json(meta_path)
        if metadata.get("provider") == "openai":
            return _thumbnail_response(
                image_path=image_path,
                prompt=str(metadata.get("prompt") or ""),
                landmark=str(metadata.get("landmark") or place_name),
                cached=True,
            )

    landmark = _resolve_landmark(request)
    prompt = _build_image_prompt(request, landmark)
    _generate_with_openai(prompt, image_path)

    _write_json(
        meta_path,
        {
            "provider": "openai",
            "model": OPENAI_IMAGE_MODEL,
            "size": OPENAI_IMAGE_SIZE,
            "quality": OPENAI_IMAGE_QUALITY,
            "outputFormat": OPENAI_IMAGE_FORMAT,
            "prompt": prompt,
            "landmark": landmark,
            "placeId": request.placeId,
            "placeName": place_name,
            "country": request.country,
        },
    )

    return _thumbnail_response(
        image_path=image_path,
        prompt=prompt,
        landmark=landmark,
        cached=False,
    )


def _thumbnail_response(
    image_path: Path,
    prompt: str,
    landmark: str,
    cached: bool,
) -> GenerateTripThumbnailResponse:
    return GenerateTripThumbnailResponse(
        imageUrl=f"{PUBLIC_BASE_URL.rstrip('/')}/static/cache/{image_path.name}",
        prompt=_trim_text(prompt, TRIP_API_COVER_PROMPT_MAX_LENGTH),
        landmark=landmark,
        cached=cached,
    )


def _cache_key(request: GenerateTripThumbnailRequest) -> str:
    if request.placeId:
        raw = request.placeId
    else:
        raw = "|".join(
            [
                request.placeName,
                request.city or "",
                request.province or "",
                request.country or "",
                str(request.latitude or ""),
                str(request.longitude or ""),
            ]
        )
    raw = "|".join(
        [
            raw,
            OPENAI_IMAGE_MODEL,
            OPENAI_IMAGE_SIZE,
            OPENAI_IMAGE_QUALITY,
            OPENAI_IMAGE_FORMAT,
        ]
    )
    return hashlib.sha256(raw.lower().encode("utf-8")).hexdigest()[:24]


def _resolve_landmark(request: GenerateTripThumbnailRequest) -> str:
    ollama_enabled = os.getenv("AI_IMAGE_USE_OLLAMA", "true").lower() in {
        "1",
        "true",
        "yes",
    }
    if ollama_enabled:
        landmark = _try_resolve_landmark_with_ollama(request)
        if landmark:
            return landmark

    return _best_location_label(request)


def _try_resolve_landmark_with_ollama(
    request: GenerateTripThumbnailRequest,
) -> str | None:
    prompt = (
        "You are selecting one famous real-world landmark or iconic scenery "
        "for a photorealistic travel cover. Do not invent fantasy places. "
        "Return only the landmark/location name, no sentence.\n\n"
        f"Place name: {request.placeName}\n"
        f"Formatted address: {request.formattedAddress or ''}\n"
        f"City: {request.city or ''}\n"
        f"Province/state: {request.province or ''}\n"
        f"Country: {request.country or ''}\n"
        f"Coordinates: {request.latitude or ''}, {request.longitude or ''}\n"
    )
    payload = json.dumps(
        {
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.2, "num_predict": 32},
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        f"{OLLAMA_BASE_URL.rstrip('/')}/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            body = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None

    value = _sanitize_landmark(str(body.get("response") or ""))
    return value or None


def _build_image_prompt(
    request: GenerateTripThumbnailRequest,
    landmark: str,
) -> str:
    country = request.country or "Unknown country"
    focus = landmark if landmark else request.placeName
    address = request.formattedAddress or ""
    city = request.city or ""
    province = request.province or ""
    return "\n".join(
        [
            "Create a photorealistic travel cover photo for a real destination.",
            "The image must look like authentic professional travel photography, not an illustration, not concept art, and not a fantasy scene.",
            "",
            "Exact destination name:",
            request.placeName,
            "",
            "Formatted address:",
            address,
            "",
            "City / province / country:",
            f"{city} / {province} / {country}",
            "",
            "Country:",
            country,
            "",
            "Primary landmark or recognizable scenery to focus on:",
            focus,
            "",
            "If this is a city or region, choose a famous real landmark, skyline, beach, lake, bridge, temple, old town, or natural scene that is strongly associated with that exact destination.",
            "Do not generate generic mountains, generic beaches, generic forests, or random scenery unless those are genuinely recognizable for this destination.",
            "Do not invent buildings or landmarks.",
            "",
            "Golden hour lighting.",
            "Beautiful sky.",
            "Natural colors, realistic atmosphere, high detail.",
            "Wide cinematic composition suitable for a mobile trip cover.",
            "No people.",
            "No text.",
            "No logo.",
            "No watermark.",
            "Ultra HD.",
            "Tourism promotion quality.",
        ]
    )


def _best_location_label(request: GenerateTripThumbnailRequest) -> str:
    for value in (
        request.formattedAddress,
        request.city,
        request.province,
        request.placeName,
    ):
        normalized = _normalize_text(value or "")
        if normalized:
            return normalized
    return request.placeName


def _sanitize_landmark(value: str) -> str:
    text = value.strip().strip('"').strip("'")
    text = re.sub(r"[\r\n]+", " ", text)
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"^(landmark|location|place)\s*:\s*", "", text, flags=re.I)
    return text[:120].strip()


def _normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def _trim_text(value: str, max_length: int) -> str:
    text = value.strip()
    return text if len(text) <= max_length else text[:max_length]


def _generate_with_openai(prompt: str, output_path: Path) -> None:
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail=(
                "OPENAI_API_KEY is not configured. Add your OpenAI API key "
                "to enable destination thumbnail generation."
            ),
        )

    payload = {
        "model": OPENAI_IMAGE_MODEL,
        "prompt": prompt,
        "n": 1,
        "size": OPENAI_IMAGE_SIZE,
        "quality": OPENAI_IMAGE_QUALITY,
        "output_format": OPENAI_IMAGE_FORMAT,
    }
    request = urllib.request.Request(
        "https://api.openai.com/v1/images/generations",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            body = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="ignore")
        raise HTTPException(
            status_code=502,
            detail=f"OpenAI image generation failed: {detail[:500]}",
        ) from exc
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as exc:
        raise HTTPException(
            status_code=502,
            detail=f"OpenAI image generation failed: {exc}",
        ) from exc

    image_data = (body.get("data") or [{}])[0]
    b64_json = image_data.get("b64_json")
    if b64_json:
        output_path.write_bytes(base64.b64decode(b64_json))
        return

    url = image_data.get("url")
    if url:
        try:
            with urllib.request.urlopen(url, timeout=90) as response:
                output_path.write_bytes(response.read())
            return
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Could not download generated image URL: {exc}",
            ) from exc

    raise HTTPException(
        status_code=502,
        detail="OpenAI image generation response did not include image data.",
    )


def _image_extension() -> str:
    output_format = OPENAI_IMAGE_FORMAT.lower().strip()
    if output_format == "jpeg":
        return "jpg"
    if output_format in {"png", "webp"}:
        return output_format
    return "png"


def _read_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
