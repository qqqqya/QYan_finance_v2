. (Join-Path $PSScriptRoot 'environment.ps1')
Push-Location $projectRoot
try {
    & "$env:FLUTTER_ROOT\bin\flutter.bat" gen-l10n
    if ($LASTEXITCODE -ne 0) { throw 'Localization generation failed.' }
    & "$env:FLUTTER_ROOT\bin\dart.bat" run build_runner build
    if ($LASTEXITCODE -ne 0) { throw 'Database code generation failed.' }
    & "$env:FLUTTER_ROOT\bin\flutter.bat" analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
    # Keep large-backup tests and widget engines within this dev machine's RAM.
    & "$env:FLUTTER_ROOT\bin\flutter.bat" test --no-pub --concurrency=1 --exclude-tags=layout-matrix
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    # All 432 combinations still run. A new engine per palette releases native
    # render allocations on memory-constrained Windows development machines.
    foreach ($palette in @('red', 'green', 'purple', 'blue')) {
        & "$env:FLUTTER_ROOT\bin\flutter.bat" test --no-pub --concurrency=1 test/stage5_layout_test.dart --plain-name="T22 $palette "
        if ($LASTEXITCODE -ne 0) { throw "Layout tests failed: $palette" }
    }
    & (Join-Path $PSScriptRoot 'check-backup.ps1')
} finally {
    Pop-Location
}
