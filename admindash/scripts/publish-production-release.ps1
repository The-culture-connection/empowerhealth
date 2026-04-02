# Publish Production Release (PowerShell)
# Uploads the latest commit and metadata to production release

$ErrorActionPreference = "Stop"

Write-Host "🚀 Publishing Production Release" -ForegroundColor Green

# Get current directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR

# Check if we're in a git repository
if (-not (Test-Path "$PROJECT_DIR\.git")) {
    Write-Host "Error: Not in a git repository" -ForegroundColor Red
    exit 1
}

# Get latest commit info
$COMMIT_SHA = git rev-parse HEAD
$COMMIT_SHORT = git rev-parse --short HEAD
$COMMIT_MESSAGE = git log -1 --pretty=%B
$COMMIT_DATE = (git log -1 --pretty=%ci).Split(' ')[0]
$COMMIT_AUTHOR = git log -1 --pretty=%an

Write-Host "Commit: $COMMIT_SHORT" -ForegroundColor Yellow
Write-Host "Date: $COMMIT_DATE" -ForegroundColor Yellow
Write-Host "Author: $COMMIT_AUTHOR" -ForegroundColor Yellow
Write-Host ""

# Check if pubspec.yaml exists (Flutter app)
$PUBSPEC_PATH = Join-Path (Split-Path -Parent $PROJECT_DIR) "pubspec.yaml"
if (Test-Path $PUBSPEC_PATH) {
    Write-Host "📦 Reading version from pubspec.yaml" -ForegroundColor Green
    $PUBSPEC_VERSION = (Get-Content $PUBSPEC_PATH | Select-String "^version:").ToString().Replace("version:", "").Trim()
    $VERSION_NAME = $PUBSPEC_VERSION.Split('+')[0]
    $BUILD_NUMBER = $PUBSPEC_VERSION.Split('+')[1]
} else {
    Write-Host "⚠️  pubspec.yaml not found, using commit-based version" -ForegroundColor Yellow
    $VERSION_NAME = "0.0.0"
    $BUILD_NUMBER = (git rev-list --count HEAD)
}

Write-Host "Version: $VERSION_NAME+$BUILD_NUMBER" -ForegroundColor Green
Write-Host ""

# Process feature changes
Write-Host "📝 Processing feature changes..." -ForegroundColor Green
Set-Location $PROJECT_DIR
node scripts/process-feature-changes.js $COMMIT_SHA $COMMIT_MESSAGE

# Get Firebase project ID
$FIREBASE_PROJECT = (firebase use 2>&1 | Select-String -Pattern '\* (.+)' | ForEach-Object { $_.Matches.Groups[1].Value })
if (-not $FIREBASE_PROJECT) {
    $FIREBASE_PROJECT = "empower-health-watch"
}

# Call Firebase Cloud Function to publish release
Write-Host "☁️  Publishing to Firebase..." -ForegroundColor Green

$BRANCH = git branch --show-current

$DATA = @{
    pubspecVersionLine = "version: $VERSION_NAME+$BUILD_NUMBER"
    commitSha = $COMMIT_SHA
    branch = $BRANCH
    gitTag = $null
    featureDossierJson = "{}"
    environment = "production"
    railwayDeployment = $null
} | ConvertTo-Json -Compress

firebase functions:call publishRelease --data $DATA --project $FIREBASE_PROJECT

Write-Host ""
Write-Host "✅ Production release published successfully!" -ForegroundColor Green
Write-Host "   Version: $VERSION_NAME+$BUILD_NUMBER" -ForegroundColor Green
Write-Host "   Commit: $COMMIT_SHORT" -ForegroundColor Green
