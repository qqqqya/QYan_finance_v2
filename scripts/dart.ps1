param([Parameter(ValueFromRemainingArguments = $true)][string[]]$DartArguments)
. (Join-Path $PSScriptRoot 'environment.ps1')
& (Join-Path $env:FLUTTER_ROOT 'bin\dart.bat') @DartArguments
exit $LASTEXITCODE
