# Installs the app on the connected device/emulator and streams its logs to logs\app.log.
# Usage: .\scripts\run-app.ps1 [-Mode flutter|apk] [-PortalUrl http://100.88.208.52:3000]
#   flutter : `flutter run` (hot reload, Dart logs + stack traces) — recommended while developing
#   apk     : installs dist\app-x86_64-release.apk then tails logcat
param(
  [ValidateSet('flutter', 'apk')][string]$Mode = 'flutter',
  [string]$PortalUrl = 'http://100.88.208.52:3000'
)

$env:ANDROID_HOME = 'C:\src\android-sdk'
$env:JAVA_HOME = 'C:\src\jdk17'
$env:Path = "C:\src\flutter\bin;C:\src\jdk17\bin;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\platform-tools;$env:Path"
$root = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force "$root\logs" | Out-Null
$log = "$root\logs\app.log"

$device = ((& adb devices) -match '\s+device$' | Select-Object -First 1) -replace '\s+device$', ''
if (-not $device) { Write-Error 'No device connected. Run .\scripts\emulator.ps1 first.'; exit 1 }
Write-Host "Device: $device"

if ($Mode -eq 'flutter') {
  Push-Location "$root\apps\mobile"
  # Tee keeps the console interactive (r = hot reload, R = restart, q = quit) while writing the log.
  flutter run -d $device --dart-define=PORTAL_URL=$PortalUrl 2>&1 | Tee-Object -FilePath $log
  Pop-Location
} else {
  $apk = Get-ChildItem "$root\dist\app-x86_64-release.apk" -ErrorAction SilentlyContinue
  if (-not $apk) { $apk = Get-ChildItem "$root\apps\mobile\build\app\outputs\flutter-apk\app-x86_64-release.apk" }
  & adb -s $device install -r $apk.FullName
  & adb -s $device logcat -c
  & adb -s $device shell monkey -p com.multiptv.app -c android.intent.category.LAUNCHER 1 | Out-Null
  Write-Host "Logging to $log (Ctrl+C to stop)"
  & adb -s $device logcat -v time flutter:V MultIPTV:V mpv:I AndroidRuntime:E ActivityManager:I *:S 2>&1 | Tee-Object -FilePath $log
}
