$FlutterArguments = $args
. (Join-Path $PSScriptRoot 'environment.ps1')
& (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat') @FlutterArguments
exit $LASTEXITCODE
