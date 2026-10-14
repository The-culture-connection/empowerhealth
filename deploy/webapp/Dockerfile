# QA web suite for Railway (service: empowerhealth-webapp).
# Railway uses this file via RAILWAY_DOCKERFILE_PATH=deploy/webapp/Dockerfile,
# building from the repo root.
#   /       QA harness (deploy/webapp/harness): checklist, device frame, debug console
#   /app/   the app under test
#   /api/   shared checklist state, stored on the Railway volume at /data

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
# Debug mode keeps Flutter's layout assertions (overflow errors); QA_HARNESS
# turns on the harness bridge in lib/qa/.
RUN flutter build web --debug --base-href /app/ --dart-define=QA_HARNESS=true -o /out/app
RUN printf '{"commit":"%s","branch":"%s"}\n' "$RAILWAY_GIT_COMMIT_SHA" "$RAILWAY_GIT_BRANCH" > /out/build.json
# Pre-compress text assets; the debug bundle is ~20 MB uncompressed.
RUN find /out -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.json' -o -name '*.wasm' -o -name '*.html' -o -name '*.otf' -o -name '*.ttf' \) -size +1k -exec gzip -9 -k {} \;

FROM node:22-alpine
ENV NODE_ENV=production SITE_DIR=/srv DATA_DIR=/data
WORKDIR /srv
COPY deploy/webapp/harness/ /srv/
COPY --from=build /out/ /srv/
COPY deploy/webapp/server/server.mjs /opt/qa/server.mjs
CMD ["node", "/opt/qa/server.mjs"]
