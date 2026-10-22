$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$env:FLUTTER_ROOT = Join-Path $projectRoot '.tooling\flutter'
$env:ANDROID_HOME = Join-Path $projectRoot '.tooling\android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $projectRoot '.tooling\android-user'
$env:ANDROID_AVD_HOME = Join-Path $projectRoot '.tooling\avd'
$env:PUB_CACHE = Join-Path $projectRoot '.tooling\pub-cache'
$env:GRADLE_USER_HOME = Join-Path $projectRoot '.tooling\gradle'
$env:TEMP = Join-Path $projectRoot '.tooling\temp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
$env:JAVA_HOME = 'D:\andriod studio\jbr'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
# Flutter's documented CFUG mirror avoids stalled engine downloads on this network.
# This changes only the current process; callers can explicitly select another host.
if (-not $env:FLUTTER_STORAGE_BASE_URL) {
    $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
}
$env:PATH = "$env:FLUTTER_ROOT\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;$env:PATH"
