. (Join-Path $PSScriptRoot 'environment.ps1')
Push-Location $projectRoot
try {
    & "$env:FLUTTER_ROOT\bin\flutter.bat" gen-l10n
    if ($LASTEXITCODE -ne 0) { throw 'Localization generation failed.' }
    & "$env:FLUTTER_ROOT\bin\dart.bat" run build_runner build
    if ($LASTEXITCODE -ne 0) { throw 'Database code generation failed.' }
    & "$env:FLUTTER_ROOT\bin\flutter.bat" analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
    & "$env:FLUTTER_ROOT\bin\flutter.bat" test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    & (Join-Path $PSScriptRoot 'check-backup.ps1')
} finally {
    Pop-Location
}
