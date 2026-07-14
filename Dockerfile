# FusionAI — Docker deploy for Render
#
# Why this exists: the FusionOS "real headless Chromium" feature (screenshot / PDF / DOM
# render of arbitrary URLs) needs an actual Chromium binary on the host. Render's default
# native Python runtime cannot install system packages at runtime (no root once the app is
# serving traffic), so `apt-get install chromium` from inside the running app is a dead end.
# Docker fixes this because `apt-get` runs during the BUILD step, with full permissions, and
# the installed binary is baked into the image — it survives restarts and Render's ephemeral
# disk wipe (that wipe only affects writable runtime disk, not the image layers).
#
# To use: in the Render dashboard, change this service's Environment/Runtime to "Docker"
# and point it at this Dockerfile (repo root). No other code changes are needed — the app
# already looks for chromium/chromium-browser on PATH.

FROM python:3.12-slim

# System deps: chromium itself + the shared libraries it needs headless (fonts, nss, etc.)
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    chromium \
    fonts-liberation \
    libnss3 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libasound2 \
    libgbm1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1
EXPOSE 10000

# Render sets $PORT; the app already reads it via os.environ.
CMD ["python3", "fusionai.py"]
