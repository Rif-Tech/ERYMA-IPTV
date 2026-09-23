# Starts an Android emulator (phone or tv) and waits until it is ready.
# Usage: .\scripts\emulator.ps1 [-Target phone|tv]
param([ValidateSet('phone', 'tv')][string]$Target = 'tv')

$env:ANDROID_HOME = 'C:\src\android-sdk'
$env:JAVA_HOME = 'C:\src\jdk17'
$env:Path = "C:\src\flutter\bin;C:\src\jdk17\bin;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\platform-tools;$env:Path"

$avd = if ($Target -eq 'tv') { 'multiptv_tv' } else { 'multiptv_phone' }

# Extended Controls > D-pad and the host arrow keys/Enter only reach the guest with these flags.
$config = Join-Path $env:USERPROFILE ".android\avd\$avd.avd\config.ini"
if (Test-Path $config) {
  $ini = Get-Content $config
  foreach ($kv in @(@('hw.dPad', 'yes'), @('hw.keyboard', 'yes'), @('hw.mainKeys', 'yes'))) {
    $line = "$($kv[0]) = $($kv[1])"
    if ($ini -match "^$([regex]::Escape($kv[0]))\s*=") { $ini = $ini -replace "^$([regex]::Escape($kv[0]))\s*=.*$", $line } else { $ini += $line }
  }
  Set-Content -Path $config -Value $ini
}

$running = (& adb devices) -match 'emulator-\d+\s+device'
if ($running) {
  Write-Host "An emulator is already running: $running"
} else {
  Write-Host "Starting $avd..."
  Start-Process -FilePath "$env:ANDROID_HOME\emulator\emulator.exe" -ArgumentList @('-avd', $avd, '-gpu', 'auto', '-no-snapshot-load', '-no-boot-anim', '-no-metrics') -WindowStyle Normal
  do {
    Start-Sleep -Seconds 3
    $booted = (cmd /c "adb shell getprop sys.boot_completed 2>nul" | Out-String).Trim()
  } while ($booted -ne '1')
  Write-Host 'Emulator booted.'
}
& adb devices
