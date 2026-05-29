# Creates upload keystore + keystore.properties (gitignored).
# Run from repo root: .\android-release\scripts\create-keystore.ps1

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $repoRoot

$keystoreDir = Join-Path $repoRoot "android-release\keystore"
$keystorePath = Join-Path $keystoreDir "upload-keystore.jks"
$propsPath = Join-Path $repoRoot "android-release\keystore.properties"

if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists: $keystorePath"
    Write-Host "Delete it first if you intentionally need a new one."
    exit 0
}

New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

function New-RandomPassword {
    param([int]$Length = 24)
    $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@`$%"
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

$password = New-RandomPassword

$dname = "CN=EmpowerHealth Watch, OU=Mobile, O=Culture Connection Technology Solutions, C=US"

keytool -genkey -v `
    -keystore $keystorePath `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $password `
    -keypass $password `
    -dname $dname

$storeFileRelative = "../../android-release/keystore/upload-keystore.jks"

@"
storePassword=$password
keyPassword=$password
keyAlias=upload
storeFile=$storeFileRelative
"@ | Set-Content -Path $propsPath -Encoding ascii

Write-Host ""
Write-Host "Created:"
Write-Host "  $keystorePath"
Write-Host "  $propsPath"
Write-Host ""
Write-Host "IMPORTANT: Back up the .jks file and keystore.properties to a password manager / secure vault."
Write-Host "Release SHA-1:"
keytool -list -v -keystore $keystorePath -alias upload -storepass $password -keypass $password 2>$null | Select-String "SHA1:"
