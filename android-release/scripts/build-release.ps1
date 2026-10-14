# Build release AAB and archive under android-release/builds/
# Run from repo root: .\android-release\scripts\build-release.ps1

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $repoRoot

$keystorePath = Join-Path $repoRoot "android-release\keystore\upload-keystore.jks"
$propsPath = Join-Path $repoRoot "android-release\keystore.properties"

if (-not (Test-Path $keystorePath)) {
    Write-Host "No upload keystore found. Running create-keystore.ps1 ..."
    & (Join-Path $PSScriptRoot "create-keystore.ps1")
}

if (-not (Test-Path $propsPath)) {
    Write-Error "Missing android-release\keystore.properties"
}

# Parse version from pubspec.yaml (version: 1.0.0+19)
$pubspec = Get-Content (Join-Path $repoRoot "pubspec.yaml") -Raw
if ($pubspec -match 'version:\s*([\d.]+)\+(\d+)') {
    $versionName = $Matches[1]
    $versionCode = $Matches[2]
    $versionTag = "$versionName+$versionCode"
} else {
    $versionTag = "unknown"
}

Write-Host "Building app bundle for $versionTag ..."
flutter clean
flutter pub get
flutter build appbundle --release

$src = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
$buildsDir = Join-Path $repoRoot "android-release\builds"
New-Item -ItemType Directory -Force -Path $buildsDir | Out-Null
$dest = Join-Path $buildsDir "empowerhealthwatch-$versionTag.aab"
Copy-Item $src $dest -Force

Write-Host ""
Write-Host "Release bundle ready:"
Write-Host "  $dest"
Write-Host ""
Write-Host "Upload this file in Google Play Console."
Write-Host "Log the release in android-release\RELEASES.md"
