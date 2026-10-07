# Flutter web app for Railway (service: empowerhealth-webapp).
# Railway uses this file via RAILWAY_DOCKERFILE_PATH=deploy/webapp/Dockerfile,
# building from the repo root.

# Keep in sync with the Flutter version used locally.
FROM ghcr.io/cirruslabs/flutter:3.41.6 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

FROM caddy:2-alpine
COPY deploy/webapp/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build/web /srv
