# QA web suite for Railway (service: empowerhealth-webapp).
# Railway uses this file via RAILWAY_DOCKERFILE_PATH=deploy/webapp/Dockerfile,
# building from the repo root.
#   /      QA harness (deploy/webapp/harness): checklist, device frame, debug console
#   /app/  the app under test

# Keep in sync with the Flutter version used locally.
FROM ghcr.io/cirruslabs/flutter:3.41.6 AS build
ARG RAILWAY_GIT_COMMIT_SHA
ARG RAILWAY_GIT_BRANCH
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# Map widget classes to source for layout findings (web has no creation tracking).
RUN dart run tool/gen_qa_widget_index.dart
# Debug mode keeps Flutter's layout assertions (overflow errors) and widget
# source locations; QA_HARNESS turns on the harness bridge in lib/qa/.
RUN flutter build web --debug --base-href /app/ --dart-define=QA_HARNESS=true -o /out/app
RUN printf '{"commit":"%s","branch":"%s"}\n' "$RAILWAY_GIT_COMMIT_SHA" "$RAILWAY_GIT_BRANCH" > /out/build.json

FROM caddy:2-alpine
COPY deploy/webapp/Caddyfile /etc/caddy/Caddyfile
COPY deploy/webapp/harness/ /srv/
COPY --from=build /out/ /srv/
