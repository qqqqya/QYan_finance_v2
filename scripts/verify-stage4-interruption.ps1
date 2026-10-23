# Precondition: roundtrip completed, QA data page contains the small all-entity fixture.
param([switch]$PreviewReady)
. "$PSScriptRoot\stage4-ui-helpers.ps1"
Start-Transcript (Join-Path $evidence 'stage4-interruption-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    if (-not $PreviewReady) { Import-Preview 'QA_large.moneybak' }
    $node = Seek '^(Replace and restore|確認覆蓋還原|确认覆盖恢复)$'
    $point = Point $node
    Adb @('shell','input','tap',"$($point[0])","$($point[1])") | Out-Null
    # Stop only after SQLite creates the rollback journal, proving an active write.
    $result = Adb @('shell','for i in $(seq 1 300); do if run-as com.example.finance_app test -f files/finance.sqlite-journal; then am force-stop com.example.finance_app; echo KILLED_WITH_SQLITE_WRITE_JOURNAL; exit 0; fi; sleep 0.02; done; echo NO_ACTIVE_WRITE_OBSERVED; exit 1')
    Write-Output $result
    Check ($result -contains 'KILLED_WITH_SQLITE_WRITE_JOURNAL') 'Did not observe an active SQLite write; interruption is not proven.'
    $launch = Adb @('shell','am','start','-W','-n',"$package/.MainActivity")
    Check ([bool]($launch -match '^Status: ok$')) 'Recovery restart failed.'
    Start-Sleep -Seconds 2
    Data-Page
    $name = "QA_stage4_after_kill_$([DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')).moneybak"
    Export-Verified $name
    $path = Join-Path $evidence 'stage4-native-paths.json'
    $paths = Get-Content $path -Raw | ConvertFrom-Json -AsHashtable
    $paths.afterKill = $name
    $paths | ConvertTo-Json | Set-Content $path -Encoding utf8
    Write-Output 'PASS: app stopped during observed SQLite write; cold restart and actual backup export succeeded. Field equality checked separately.'
} finally { Stop-Transcript | Out-Null }
