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

# Set working directory
WORKDIR /app

# Copy configuration files first to cache dependencies
COPY pubspec.yaml pubspec.lock ./

# Get packages
RUN flutter pub get

# Copy all source files
COPY . .

# Generate Riverpod/Freezed files
RUN flutter pub run build_runner build --delete-conflicting-outputs

# Build the web app with the target API URL
ARG API_URL=http://localhost:5000
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
