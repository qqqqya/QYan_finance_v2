# This flow resets only the dedicated disposable Finance_API_36 AVD.
. "$PSScriptRoot\stage5-ui-helpers.ps1"
& "$PSScriptRoot\flutter.ps1" test integration_test/refinement_flow_test.dart --device-id=emulator-5560 --dart-define=FINANCE_QA_DISPOSABLE=true --reporter=expanded 2>&1 | Tee-Object (Join-Path $evidence 'refinement-android-flow.txt')
if($LASTEXITCODE -ne 0){ throw 'Android refinement checks failed.' }
