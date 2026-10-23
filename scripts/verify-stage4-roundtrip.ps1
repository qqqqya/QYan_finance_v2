# Precondition: stage4 QA app data page after importing stage4-all-types.moneybak.
# QA fixture files are created by backup_resource_test.dart with FINANCE_WRITE_QA_FIXTURES=true.
param([string]$ResumeStamp)
. "$PSScriptRoot\stage4-ui-helpers.ps1"
$stamp = if ($ResumeStamp) { $ResumeStamp } else { [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss') }
$paths = @{
    a = "QA_stage4_A_$stamp.moneybak"
    b = "QA_stage4_B_$stamp.moneybak"
    recovered = "QA_stage4_private_$stamp.moneybak"
    beforeReset = "QA_stage4_before_reset_$stamp.moneybak"
    zero = "QA_stage4_zero_$stamp.moneybak"
}
Start-Transcript (Join-Path $evidence 'stage4-roundtrip-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    if (-not $ResumeStamp) {
        Export-Verified $paths.a
        Click '^預覽並還原副本$'
        Click '^取消$'
        Click '^預覽並還原副本$'
        Confirm-Restore
        Export-Verified $paths.recovered
    }
    Click '^Preview & restore copy$'
    Confirm-Restore
    # Cancel export and import at the real Android picker.
    Top; Click '^匯出備份'; Back
    Check ((Ui 'stage4-export-cancel').OuterXml -notmatch '備份成功') 'Canceled export falsely succeeded.'
    Top; Click '^匯入還原'; Back
    Check ((Ui 'stage4-import-cancel').OuterXml -notmatch '還原完成') 'Canceled import falsely succeeded.'
    # Reset cancel, then export-first and final destructive confirmation.
    Click '^恢復原廠設定$'; Click '^取消$'
    Click '^恢復原廠設定$'; Click '^先匯出備份$'
    Save-Document $paths.beforeReset
    Check ((Ui).OuterXml -match '備份成功') 'Pre-reset export failed.'
    Click '^完成$'
    Check ((Ui).OuterXml -match '確認清空') 'Reset did not require final confirmation after export.'
    Click '^確認清空$'
    Check ((Ui 'stage4-reset-success').OuterXml -match 'Factory reset complete') 'Reset failed.'
    Click '^Done$'
    Export-Verified $paths.zero
    Check ((Ui 'stage4-reset-no-copy').OuterXml -match 'No before-restore copy') 'Private copy remained after reset.'
    $cache = Adb @('shell','run-as',$package,'ls','cache')
    Check ($cache -notcontains 'backups_share') 'Private share cache remained after reset.'
    Adb @('shell','ls',"/sdcard/Download/$($paths.a)") | Out-Null
    # Empty-book restore and duplicate restore must not add rows.
    Import-Preview $paths.a; Confirm-Restore
    Import-Preview $paths.a; Confirm-Restore
    Export-Verified $paths.b
    Restart
    Data-Page
    Top; Shot 'data-management-dark'
    Click '^刪除私有副本$'; Click '^刪除$'
    $paths | ConvertTo-Json | Set-Content (Join-Path $evidence 'stage4-native-paths.json') -Encoding utf8
    Write-Output 'PASS: actual file round-trip, private-copy restore/swap, duplicate imports, cancellation, export-first reset, private cache cleanup, external file preservation and cold restart.'
} finally { Stop-Transcript | Out-Null }
