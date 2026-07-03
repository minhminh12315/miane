from __future__ import annotations

import hashlib
import os
import random
import re
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pydantic import BaseModel, Field


CACHE_DIR = Path(os.getenv("AI_IMAGE_CACHE_DIR", "cache")).resolve()
PUBLIC_BASE_URL = os.getenv("AI_IMAGE_PUBLIC_BASE_URL", "http://localhost:8000")
CACHE_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="MIANE AI Image Service", version="0.1.0")
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


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/generate-trip-image", response_model=GenerateTripImageResponse)
def generate_trip_image(
    request: GenerateTripImageRequest,
) -> GenerateTripImageResponse:
    destination = _normalize_destination(request.destination)
    if not destination:
        raise HTTPException(status_code=400, detail="Destination is required")

    cache_key = hashlib.sha256(destination.lower().encode("utf-8")).hexdigest()[:18]
    image_path = CACHE_DIR / f"{cache_key}.png"
    if image_path.exists():
        return _response(image_path, cached=True)

    prompt = (
        f"A cinematic aerial travel photograph of {destination}, "
        "beautiful scenery, golden sunset, high quality, ultra realistic, "
        "tourism advertisement."
    )
    generated = _try_generate_with_diffusers(prompt, image_path)
    if not generated:
        _generate_placeholder(destination, image_path)

    return _response(image_path, cached=False)


def _response(image_path: Path, cached: bool) -> GenerateTripImageResponse:
    return GenerateTripImageResponse(
        imageUrl=f"{PUBLIC_BASE_URL.rstrip('/')}/static/cache/{image_path.name}",
        cached=cached,
    )


def _normalize_destination(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def _try_generate_with_diffusers(prompt: str, output_path: Path) -> bool:
    """Optional local AI backend.

    Install diffusers/torch separately and set AI_IMAGE_BACKEND=diffusers.
    The fallback keeps development lightweight and deterministic.
    """
    if os.getenv("AI_IMAGE_BACKEND", "").lower() != "diffusers":
        return False
    try:
        import torch  # type: ignore
        from diffusers import AutoPipelineForText2Image  # type: ignore

        model = os.getenv(
            "AI_IMAGE_DIFFUSERS_MODEL",
            "stabilityai/sdxl-turbo",
        )
        pipe = AutoPipelineForText2Image.from_pretrained(
            model,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            variant="fp16" if torch.cuda.is_available() else None,
        )
        if torch.cuda.is_available():
            pipe = pipe.to("cuda")
        image = pipe(
            prompt=prompt,
            num_inference_steps=4,
            guidance_scale=0.0,
            width=1024,
            height=768,
        ).images[0]
        image.save(output_path)
        return True
    except Exception:
        return False


def _generate_placeholder(destination: str, output_path: Path) -> None:
    width, height = 1280, 860
    seed = int(hashlib.sha256(destination.encode("utf-8")).hexdigest()[:8], 16)
    rng = random.Random(seed)
    hue = rng.randint(190, 330)

    image = Image.new("RGB", (width, height), _hsv_to_rgb(hue, 52, 35))
    draw = ImageDraw.Draw(image)

    for y in range(height):
        ratio = y / height
        color = _mix(
            _hsv_to_rgb(hue, 58, 42),
            _hsv_to_rgb((hue + 58) % 360, 70, 12),
            ratio,
        )
        draw.line([(0, y), (width, y)], fill=color)

    for _ in range(8):
        cx = rng.randint(-120, width + 120)
        cy = rng.randint(-80, height)
        radius = rng.randint(150, 360)
        overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(*_hsv_to_rgb((hue + rng.randint(20, 90)) % 360, 80, 86), 46),
        )
        overlay = overlay.filter(ImageFilter.GaussianBlur(radius=42))
        image = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
        draw = ImageDraw.Draw(image)

    sun_x, sun_y = int(width * 0.78), int(height * 0.28)
    draw.ellipse(
        (sun_x - 105, sun_y - 105, sun_x + 105, sun_y + 105),
        fill=(255, 173, 74),
    )

    mountain = [
        (0, int(height * 0.74)),
        (int(width * 0.22), int(height * 0.48)),
        (int(width * 0.42), int(height * 0.69)),
        (int(width * 0.64), int(height * 0.42)),
        (width, int(height * 0.72)),
        (width, height),
        (0, height),
    ]
    draw.polygon(mountain, fill=(10, 16, 24))

    for offset in range(0, 5):
        y = int(height * (0.73 + offset * 0.045))
        points = []
        for x in range(-40, width + 80, 34):
            points.append((x, y + int(10 * rng.random())))
        draw.line(points, fill=(255, 255, 255), width=2)

    title_font = _font(70)
    subtitle_font = _font(32)
    draw.text((72, height - 190), destination, fill=(255, 255, 255), font=title_font)
    draw.text(
        (76, height - 105),
        "Generated travel cover by MIANE",
        fill=(235, 241, 255),
        font=subtitle_font,
    )
    image.save(output_path, "PNG")


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for font_path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ):
        if Path(font_path).exists():
            return ImageFont.truetype(font_path, size)
    return ImageFont.load_default()


def _hsv_to_rgb(h: int, s: int, v: int) -> tuple[int, int, int]:
    import colorsys

    r, g, b = colorsys.hsv_to_rgb(h / 360, s / 100, v / 100)
    return int(r * 255), int(g * 255), int(b * 255)


def _mix(
    a: tuple[int, int, int],
    b: tuple[int, int, int],
    ratio: float,
) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1 - ratio) + b[i] * ratio) for i in range(3))
