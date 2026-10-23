# Build the real main entry point, never copy an integration test binary.
. "$PSScriptRoot\environment.ps1"
$signer = Join-Path $env:ANDROID_HOME 'build-tools\36.0.0\apksigner.bat'
$aapt = Join-Path $env:ANDROID_HOME 'build-tools\36.0.0\aapt.exe'
$ideKey = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.android\debug.keystore'
if (!(Test-Path -LiteralPath $ideKey)) { throw 'Existing IDE debug key missing; restore it, do not create a replacement.' }
& "$PSScriptRoot\prepare-release-signing.ps1"
& "$PSScriptRoot\flutter.ps1" build apk --debug --target=lib/main.dart
if($LASTEXITCODE -ne 0){throw 'Debug build failed.'}
$debug = Join-Path $projectRoot 'artifacts\finance-0.5.1-debug.apk'
$ide = Join-Path $projectRoot 'artifacts\finance-0.5.1-ide-debug.apk'
Copy-Item -LiteralPath (Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk') -Destination $debug -Force
# Android's standard public debug password; release passwords are never printed.
& $signer sign --ks $ideKey --ks-pass pass:android --key-pass pass:android --out $ide $debug
if($LASTEXITCODE -ne 0){throw 'IDE-compatible signing failed.'}
& "$PSScriptRoot\flutter.ps1" build apk --release --target=lib/main.dart
if($LASTEXITCODE -ne 0){throw 'Release build failed.'}
$release = Join-Path $projectRoot 'artifacts\finance-0.5.1-release.apk'
Copy-Item -LiteralPath (Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk') -Destination $release -Force
$manifest = foreach($item in @(@($debug,'debug main'),@($ide,'debug IDE-compatible main'),@($release,'release candidate main'))){
    $cert = (& $signer verify --print-certs $item[0]) -join "`n"
    if($LASTEXITCODE -ne 0){throw 'APK signature verification failed.'}
    $digest=[regex]::Match($cert,'certificate SHA-256 digest: ([a-f0-9]+)').Groups[1].Value
    $badging=(& $aapt dump badging $item[0]) -join "`n"
    if($LASTEXITCODE -ne 0 -or $badging -notmatch "versionCode='6' versionName='0.5.1'"){throw 'APK version metadata mismatch.'}
    if($badging -notmatch "sdkVersion:'29'" -or $badging -notmatch "targetSdkVersion:'36'"){throw 'APK SDK metadata mismatch.'}
    foreach($abi in @('armeabi-v7a','arm64-v8a','x86_64')) {
        if($badging -notmatch "native-code:.*'$abi'"){throw 'APK ABI metadata mismatch.'}
    }
    [ordered]@{file=[IO.Path]::GetFileName($item[0]);versionName='0.5.1';versionCode=6;
        bytes=(Get-Item -LiteralPath $item[0]).Length;sha256=(Get-FileHash -LiteralPath $item[0] -Algorithm SHA256).Hash.ToLowerInvariant();
        certificateSha256=$digest;minSdk=29;targetSdk=36;abis=@('arm64-v8a','armeabi-v7a','x86_64');mode=$item[1]}
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $projectRoot 'artifacts\verification\refinement-apk-manifest.json') -Encoding utf8
$old=Get-Content (Join-Path $projectRoot 'artifacts\verification\stage5-apk-manifest.json') -Raw | ConvertFrom-Json
foreach($pair in @(@('finance-stage5-debug.apk','finance-0.5.1-debug.apk'),@('finance-stage5-ide-debug.apk','finance-0.5.1-ide-debug.apk'),@('finance-stage5-release.apk','finance-0.5.1-release.apk'))){
    $before=@($old | Where-Object file -eq $pair[0])[0]
    $after=@($manifest | Where-Object file -eq $pair[1])[0]
    if($before.certificateSha256 -cne $after.certificateSha256){throw 'Existing APK signing identity changed.'}
}
'PASS: three real-main APKs built, signatures verified and unchanged from stage5.'
