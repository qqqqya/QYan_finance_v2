# Independent native integration fixtures; never clear any user device.
. "$PSScriptRoot\stage5-ui-helpers.ps1"
foreach($case in @('app_smoke_test','asset_flow_test','ledger_flow_test')){
    $installed = & $adbExe -s $device shell pm path $package 2>$null
    if($installed -match '^package:'){
        Adb @('shell','pm','clear',$package) | Out-Null
    }
    & "$PSScriptRoot\flutter.ps1" test "integration_test/$case.dart" --device-id=emulator-5560 --reporter=expanded 2>&1 | Tee-Object (Join-Path $evidence "stage5-$case.txt")
    if($LASTEXITCODE -ne 0){throw "Native regression failed: $case"}
}
