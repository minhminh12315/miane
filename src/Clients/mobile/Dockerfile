# Stage 1: Build
FROM debian:bookworm-slim AS build

# Install build dependencies
RUN apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Max-FutureTime=86400 update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Add flutter to path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to trigger download of SDK dependencies
RUN flutter doctor -v

# Enable web platform + pre-cache web SDK
RUN flutter config --enable-web && flutter precache --web

# Set working directory
WORKDIR /app

# Copy configuration files first to cache dependencies
COPY pubspec.yaml pubspec.lock ./

# Get packages
RUN flutter pub get

# Copy all source files
COPY . .

# Ensure web platform is scaffolded (no-op nếu đã có thư mục web/)
RUN flutter create --platforms web . 2>/dev/null || true

# Generate Riverpod/Freezed files
RUN flutter pub run build_runner build --delete-conflicting-outputs

FROM build AS dev
EXPOSE 3000
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "3000"]

FROM build AS release-build

# Build the web app with the target API URL
ARG API_URL=http://localhost:5000
ARG MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail
ARG FIREBASE_WEB_API_KEY=
ARG FIREBASE_WEB_AUTH_DOMAIN=
ARG FIREBASE_WEB_PROJECT_ID=
ARG FIREBASE_WEB_STORAGE_BUCKET=
ARG FIREBASE_WEB_MESSAGING_SENDER_ID=
ARG FIREBASE_WEB_APP_ID=
ARG FIREBASE_WEB_MEASUREMENT_ID=
ARG FIREBASE_WEB_VAPID_KEY=
RUN printf '{"apiKey":"%s","authDomain":"%s","projectId":"%s","storageBucket":"%s","messagingSenderId":"%s","appId":"%s","measurementId":"%s"}\n' \
  "${FIREBASE_WEB_API_KEY}" \
  "${FIREBASE_WEB_AUTH_DOMAIN}" \
  "${FIREBASE_WEB_PROJECT_ID}" \
  "${FIREBASE_WEB_STORAGE_BUCKET}" \
  "${FIREBASE_WEB_MESSAGING_SENDER_ID}" \
  "${FIREBASE_WEB_APP_ID}" \
  "${FIREBASE_WEB_MEASUREMENT_ID}" \
  > web/firebase-config.json
RUN flutter build web --release \
  --dart-define=API_URL=${API_URL} \
  --dart-define=MIANE_AI_IMAGE_URL=${MIANE_AI_IMAGE_URL} \
  --dart-define=FIREBASE_WEB_API_KEY=${FIREBASE_WEB_API_KEY} \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=${FIREBASE_WEB_AUTH_DOMAIN} \
  --dart-define=FIREBASE_WEB_PROJECT_ID=${FIREBASE_WEB_PROJECT_ID} \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=${FIREBASE_WEB_STORAGE_BUCKET} \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=${FIREBASE_WEB_MESSAGING_SENDER_ID} \
  --dart-define=FIREBASE_WEB_APP_ID=${FIREBASE_WEB_APP_ID} \
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID=${FIREBASE_WEB_MEASUREMENT_ID} \
  --dart-define=FIREBASE_WEB_VAPID_KEY=${FIREBASE_WEB_VAPID_KEY}

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=release-build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
