. "$PSScriptRoot\stage5-ui-helpers.ps1"
# The integration runner may replace/uninstall its app; this is a disposable AVD.
& "$PSScriptRoot\flutter.ps1" test integration_test/stage5_acceptance_test.dart --device-id=emulator-5560 --dart-define=FINANCE_QA_DISPOSABLE=true --reporter=expanded 2>&1 | Tee-Object (Join-Path $evidence 'stage5-android-performance.txt')
if($LASTEXITCODE -ne 0){throw 'Stage5 Android acceptance failed.'}
