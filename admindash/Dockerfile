# Admin dashboard for Railway. Built from the repo root with
# RAILWAY_DOCKERFILE_PATH=admindash/Dockerfile; admindash/Dockerfile.dockerignore
# replaces the root .dockerignore (which leaves admindash out of the Flutter build).

FROM node:22-alpine AS build
WORKDIR /app

# Vite bakes these in at build time. Railway passes service variables to
# matching build args.
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_FIREBASE_MEASUREMENT_ID
ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY \
    VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN \
    VITE_FIREBASE_PROJECT_ID=$VITE_FIREBASE_PROJECT_ID \
    VITE_FIREBASE_STORAGE_BUCKET=$VITE_FIREBASE_STORAGE_BUCKET \
    VITE_FIREBASE_MESSAGING_SENDER_ID=$VITE_FIREBASE_MESSAGING_SENDER_ID \
    VITE_FIREBASE_APP_ID=$VITE_FIREBASE_APP_ID \
    VITE_FIREBASE_MEASUREMENT_ID=$VITE_FIREBASE_MEASUREMENT_ID

COPY admindash/package.json admindash/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY admindash/ ./
RUN npm run build

FROM node:22-alpine
WORKDIR /app
RUN npm install -g serve@14 --no-audit --no-fund
COPY --from=build /app/dist ./dist
ENV PORT=8080
# serve picks up dist/serve.json (copied from public/): SPA fallback and no-cache index.html.
CMD ["sh", "-c", "serve dist -l tcp://0.0.0.0:${PORT}"]
