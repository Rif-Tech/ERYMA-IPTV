# Captures a screenshot of the connected device into logs\screenshots\<timestamp>.png
$env:Path = "C:\src\android-sdk\platform-tools;$env:Path"
$root = Split-Path $PSScriptRoot -Parent
$dir = "$root\logs\screenshots"
New-Item -ItemType Directory -Force $dir | Out-Null
$file = "$dir\$(Get-Date -Format 'yyyyMMdd-HHmmss').png"
# PowerShell redirection would re-encode the binary stream; pull the file over adb instead.
& adb shell screencap -p /sdcard/multiptv_shot.png | Out-Null
& adb pull /sdcard/multiptv_shot.png $file | Out-Null
& adb shell rm /sdcard/multiptv_shot.png | Out-Null
Write-Host $file
