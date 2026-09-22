# Builds the release APKs: one per ABI (smallest download for a given box) plus a universal one
# for the single `apk_link` published in the admin portal. Output goes to dist\.
# Usage: .\scripts\build-release.ps1 [-PortalUrl https://portail.example.com] [-SkipUniversal]
# -PortalUrl is only the offline fallback: at runtime the app uses the URL set in /admin/config.
param(
  [string]$PortalUrl = $(if ($env:PORTAL_URL) { $env:PORTAL_URL } else { 'http://100.88.208.52:3000' }),
  [switch]$SkipUniversal
)

$ErrorActionPreference = 'Stop'
$env:ANDROID_HOME = 'C:\src\android-sdk'
$env:JAVA_HOME = 'C:\src\jdk17'
$env:Path = "C:\src\flutter\bin;C:\src\jdk17\bin;$env:Path"

$root = Split-Path $PSScriptRoot -Parent
$app = "$root\apps\mobile"
$dist = "$root\dist"
New-Item -ItemType Directory -Force $dist | Out-Null

if (-not (Test-Path "$app\android\key.properties")) {
  Write-Warning 'android\key.properties not found: the APK will be signed with the DEBUG key (see key.properties.example).'
}

Push-Location $app
try {
  flutter pub get
  flutter gen-l10n
  dart run build_runner build --delete-conflicting-outputs

  # --obfuscate + --split-debug-info shrink the Dart AOT snapshot; symbols stay in build\symbols for
  # stack-trace decoding (`flutter symbolize`).
  if ($PortalUrl -match 'localhost|127\.0\.0\.1') { throw "PortalUrl '$PortalUrl' is not reachable from a TV box; pass -PortalUrl with the LAN/public address." }
  Write-Host "PORTAL_URL fallback: $PortalUrl"
  $common = @('--release', '--obfuscate', "--split-debug-info=$app\build\symbols", '--tree-shake-icons', "--dart-define=PORTAL_URL=$PortalUrl")

  flutter build apk @common --split-per-abi
  if ($LASTEXITCODE -ne 0) { throw 'split-per-abi build failed' }
  Copy-Item "$app\build\app\outputs\flutter-apk\app-*-release.apk" $dist -Force

  if (-not $SkipUniversal) {
    flutter build apk @common
    if ($LASTEXITCODE -ne 0) { throw 'universal build failed' }
    Copy-Item "$app\build\app\outputs\flutter-apk\app-release.apk" "$dist\app-universal-release.apk" -Force
  }
} finally {
  Pop-Location
}

Get-ChildItem "$dist\*.apk" | Select-Object Name, @{ n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } } | Format-Table -AutoSize
Write-Host 'Mi Box S and other 32-bit boxes: install app-armeabi-v7a-release.apk (arm64/x86_64 APKs are rejected there).'
