#!/bin/bash

# Publish Production Release
# Uploads the latest commit and metadata to production release

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Publishing Production Release${NC}"

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

# Get latest commit info
COMMIT_SHA=$(git rev-parse HEAD)
COMMIT_SHORT=$(git rev-parse --short HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_DATE=$(git log -1 --pretty=%ci | cut -d' ' -f1)
COMMIT_AUTHOR=$(git log -1 --pretty=%an)

echo -e "${YELLOW}Commit: ${COMMIT_SHORT}${NC}"
echo -e "${YELLOW}Date: ${COMMIT_DATE}${NC}"
echo -e "${YELLOW}Author: ${COMMIT_AUTHOR}${NC}"
echo ""

# Check if pubspec.yaml exists (Flutter app)
if [ -f "$PROJECT_DIR/../pubspec.yaml" ]; then
  echo -e "${GREEN}📦 Reading version from pubspec.yaml${NC}"
  PUBSPEC_VERSION=$(grep "^version:" "$PROJECT_DIR/../pubspec.yaml" | sed 's/version: //' | tr -d ' ')
  VERSION_NAME=$(echo $PUBSPEC_VERSION | cut -d'+' -f1)
  BUILD_NUMBER=$(echo $PUBSPEC_VERSION | cut -d'+' -f2)
else
  echo -e "${YELLOW}⚠️  pubspec.yaml not found, using commit-based version${NC}"
  VERSION_NAME="0.0.0"
  BUILD_NUMBER=$(git rev-list --count HEAD)
fi

echo -e "${GREEN}Version: ${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo ""

# Process feature changes
echo -e "${GREEN}📝 Processing feature changes...${NC}"
cd "$PROJECT_DIR"
node scripts/process-feature-changes.js "$COMMIT_SHA" "$COMMIT_MESSAGE"

# Call Firebase Cloud Function to publish release
echo -e "${GREEN}☁️  Publishing to Firebase...${NC}"

# Get Firebase project ID
FIREBASE_PROJECT=$(firebase use 2>&1 | grep -oP '(?<=\* ).*' || echo "empower-health-watch")

# Call publishRelease function
firebase functions:call publishRelease \
  --data "{
    \"pubspecVersionLine\": \"version: ${VERSION_NAME}+${BUILD_NUMBER}\",
    \"commitSha\": \"${COMMIT_SHA}\",
    \"branch\": \"$(git branch --show-current)\",
    \"gitTag\": null,
    \"featureDossierJson\": \"{}\",
    \"environment\": \"production\",
    \"railwayDeployment\": null
  }" \
  --project "$FIREBASE_PROJECT"

echo ""
echo -e "${GREEN}✅ Production release published successfully!${NC}"
echo -e "${GREEN}   Version: ${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo -e "${GREEN}   Commit: ${COMMIT_SHORT}${NC}"
