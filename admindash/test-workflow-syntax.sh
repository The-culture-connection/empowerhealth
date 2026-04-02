#!/bin/bash
# Test script to validate workflow JSON/jq syntax
# This simulates what the GitHub Actions workflow does

set -e

echo "Testing workflow JSON/jq syntax..."

# Simulate GitHub Actions outputs
VERSION_LINE="version: 1.0.0+13"
COMMIT_SHA="test123"
BRANCH="main"
GIT_TAG=""
ENVIRONMENT="pilot"
COMMIT_AUTHOR="Test User"
COMMIT_DATE="2026-03-06"
SECRET_TOKEN="test-token"
DEPLOYMENT_ID=""
DEPLOYMENT_URL=""
DEPLOYMENT_STATUS="success"

# Test 1: Feature dossier (base64 approach)
echo ""
echo "Test 1: Feature dossier base64 encoding..."
DOSSIER_JSON='{"summary":"","categories":[]}'
echo "$DOSSIER_JSON" | jq -c . > dossier_temp.json
DOSSIER_B64=$(base64 -w 0 dossier_temp.json 2>/dev/null || base64 dossier_temp.json | tr -d '\n')
echo "Dossier base64: $DOSSIER_B64"

# Decode and verify
DECODED_DOSSIER=$(echo "$DOSSIER_B64" | base64 -d 2>/dev/null || echo "$DOSSIER_B64" | base64 -d)
echo "Decoded dossier: $DECODED_DOSSIER"
if echo "$DECODED_DOSSIER" | jq . > /dev/null 2>&1; then
  echo "✓ Dossier JSON is valid"
else
  echo "✗ Dossier JSON is invalid"
  exit 1
fi

# Test 2: Commit message (base64 approach)
echo ""
echo "Test 2: Commit message base64 encoding..."
COMMIT_MESSAGE_RAW="Test commit message\n\nWith newlines"
COMMIT_MESSAGE_JSON=$(echo "$COMMIT_MESSAGE_RAW" | jq -Rs .)
COMMIT_MESSAGE_B64=$(echo "$COMMIT_MESSAGE_JSON" | base64 -w 0 2>/dev/null || echo "$COMMIT_MESSAGE_JSON" | base64 | tr -d '\n')
echo "Commit message base64: $COMMIT_MESSAGE_B64"

# Decode and verify
DECODED_COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE_B64" | base64 -d 2>/dev/null || echo "$COMMIT_MESSAGE_B64" | base64 -d)
echo "Decoded commit message: $DECODED_COMMIT_MESSAGE"
if echo "$DECODED_COMMIT_MESSAGE" | jq . > /dev/null 2>&1; then
  echo "✓ Commit message JSON is valid"
else
  echo "✗ Commit message JSON is invalid"
  exit 1
fi

# Test 3: Railway deployment
echo ""
echo "Test 3: Railway deployment JSON..."
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RAILWAY_DEPLOYMENT=$(jq -n \
  --arg deploymentId "$DEPLOYMENT_ID" \
  --arg deploymentUrl "$DEPLOYMENT_URL" \
  --arg status "$DEPLOYMENT_STATUS" \
  --arg deployedAt "$DEPLOYED_AT" \
  '{
    "deploymentId": $deploymentId,
    "deploymentUrl": $deploymentUrl,
    "status": $status,
    "deployedAt": $deployedAt
  }')
echo "Railway deployment: $RAILWAY_DEPLOYMENT"
if echo "$RAILWAY_DEPLOYMENT" | jq . > /dev/null 2>&1; then
  echo "✓ Railway deployment JSON is valid"
else
  echo "✗ Railway deployment JSON is invalid"
  exit 1
fi

# Test 4: Full request payload
echo ""
echo "Test 4: Full request payload..."
REQUEST_DATA=$(jq -n \
  --arg versionLine "$VERSION_LINE" \
  --arg commitSha "$COMMIT_SHA" \
  --arg branch "$BRANCH" \
  --arg gitTag "$GIT_TAG" \
  --argjson dossier "$DECODED_DOSSIER" \
  --arg environment "$ENVIRONMENT" \
  --argjson commitMessage "$DECODED_COMMIT_MESSAGE" \
  --arg commitAuthor "$COMMIT_AUTHOR" \
  --arg commitDate "$COMMIT_DATE" \
  --argjson railwayDeployment "$RAILWAY_DEPLOYMENT" \
  --arg secretToken "$SECRET_TOKEN" \
  '{
    "data": {
      "pubspecVersionLine": $versionLine,
      "commitSha": $commitSha,
      "branch": $branch,
      "gitTag": $gitTag,
      "featureDossierJson": $dossier,
      "environment": $environment,
      "commitMessage": $commitMessage,
      "commitAuthor": $commitAuthor,
      "commitDate": $commitDate,
      "railwayDeployment": $railwayDeployment,
      "secretToken": $secretToken
    }
  }')

echo "Request data:"
echo "$REQUEST_DATA" | jq .

if echo "$REQUEST_DATA" | jq . > /dev/null 2>&1; then
  echo "✓ Full request payload JSON is valid"
  echo ""
  echo "All tests passed! ✓"
else
  echo "✗ Full request payload JSON is invalid"
  exit 1
fi

# Cleanup
rm -f dossier_temp.json
