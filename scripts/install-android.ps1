param(
    [Parameter(Mandatory = $true)][string]$Device,
    [string]$Apk = 'artifacts\finance-stage4-ide-debug.apk',
    [switch]$Launch
)
. "$PSScriptRoot\environment.ps1"
$adbExe = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
if ([IO.Path]::GetExtension($apkPath) -ne '.apk') { throw 'Select an APK file.' }
$state = & $adbExe -s $Device get-state 2>&1
if ($LASTEXITCODE -ne 0 -or ($state -join "`n").Trim() -ne 'device') {
    throw 'Device is not authorized/online. Check adb devices and the phone authorization dialog.'
}
$api = & $adbExe -s $Device shell getprop ro.build.version.sdk
if ($LASTEXITCODE -ne 0 -or [int]$api -lt 29) { throw 'Android API 29 or later is required.' }
Write-Output "APK: $apkPath"
Write-Output "SHA-256: $((Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash)"
$result = & $adbExe -s $Device install -r $apkPath 2>&1
$result | Write-Output
if ($LASTEXITCODE -ne 0) {
    throw 'Install failed. Do not uninstall or clear data to bypass signature/version errors. Preserve the existing data and check the signing key and version.'
}
if ($Launch) {
    $launchResult = & $adbExe -s $Device shell am start -W -n com.example.finance_app/.MainActivity
    $launchResult | Write-Output
    if ($LASTEXITCODE -ne 0 -or -not ($launchResult -match '^Status: ok$')) {
        throw 'Installation succeeded, but startup was not confirmed. Check the device screen and application logs.'
    }
}
