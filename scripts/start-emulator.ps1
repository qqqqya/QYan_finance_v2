param([switch]$Headless)

. "$PSScriptRoot\environment.ps1"
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$emulator = Join-Path $env:ANDROID_HOME 'emulator\emulator.exe'
$deviceId = 'emulator-5560'
$deviceName = 'Finance_API_36'
if (-not (Test-Path -LiteralPath (Join-Path $env:ANDROID_AVD_HOME "$deviceName.ini"))) {
    throw 'Finance_API_36 is missing. Create the API 36 x86_64 AVD first (see docs/06).'
}
& $adb start-server | Out-Null
$devices = & $adb devices
if ($devices -match "^$deviceId\s+device") {
    Write-Output "$deviceId is already running."
    exit 0
}
$logRoot = Join-Path $projectRoot 'artifacts\verification'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$arguments = @('-avd', $deviceName, '-port', '5560', '-memory', '2048', '-cores', '4',
    '-gpu', 'swiftshader', '-no-audio', '-no-snapshot', '-no-boot-anim')
if ($Headless) { $arguments += '-no-window' }
Start-Process -FilePath $emulator -ArgumentList $arguments -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logRoot 'emulator-stdout.log') `
    -RedirectStandardError (Join-Path $logRoot 'emulator-stderr.log') | Out-Null
Write-Output "Starting $deviceId ($deviceName). Use .\scripts\flutter.ps1 devices to check readiness."
