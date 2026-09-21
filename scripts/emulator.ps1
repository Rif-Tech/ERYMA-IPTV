# Starts an Android emulator (phone or tv) and waits until it is ready.
# Usage: .\scripts\emulator.ps1 [-Target phone|tv]
param([ValidateSet('phone', 'tv')][string]$Target = 'tv')

$env:ANDROID_HOME = 'C:\src\android-sdk'
$env:JAVA_HOME = 'C:\src\jdk17'
$env:Path = "C:\src\flutter\bin;C:\src\jdk17\bin;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\platform-tools;$env:Path"

$avd = if ($Target -eq 'tv') { 'multiptv_tv' } else { 'multiptv_phone' }
$running = (& adb devices) -match 'emulator-\d+\s+device'
if ($running) {
  Write-Host "An emulator is already running: $running"
} else {
  Write-Host "Starting $avd..."
  Start-Process -FilePath "$env:ANDROID_HOME\emulator\emulator.exe" -ArgumentList @('-avd', $avd, '-gpu', 'auto', '-no-snapshot-load', '-no-boot-anim') -WindowStyle Normal
  do {
    Start-Sleep -Seconds 3
    $booted = (cmd /c "adb shell getprop sys.boot_completed 2>nul" | Out-String).Trim()
  } while ($booted -ne '1')
  Write-Host 'Emulator booted.'
}
& adb devices
