# Replaces the QA app ONLY. Never use this script on a phone with user data.
. "$PSScriptRoot\stage5-ui-helpers.ps1"
Start-Transcript (Join-Path $evidence 'stage5-release-native.txt') -UseMinimalHeader -Force | Out-Null
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')
$paths = @{a="QA_stage5_release_A_$stamp.moneybak";b="QA_stage5_release_B_$stamp.moneybak";
    unchanged="QA_stage5_unchanged_$stamp.moneybak";upgrade="QA_stage5_release_upgrade_$stamp.moneybak";zero="QA_stage5_zero_$stamp.moneybak"}
function Equal-Fields([string]$Left,[string]$Right,[string]$Label){
    $a=(Get-Content (Join-Path $evidence $Left) -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable).data | ConvertTo-Json -Depth 100 -Compress
    $b=(Get-Content (Join-Path $evidence $Right) -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable).data | ConvertTo-Json -Depth 100 -Compress
    Check ($a -ceq $b) "Field mismatch: $Label"
    Write-Output "PASS: $Label - every business field equal."
}
try {
    $installed=& $adbExe -s $device shell pm path $package 2>$null
    if($installed -match '^package:'){Adb @('uninstall',$package) | Write-Output}
    $apk=Join-Path $projectRoot 'artifacts\finance-stage5-release.apk'
    Adb @('install',$apk) | Write-Output
    $launch=Adb @('shell','am','start','-W','-n',"$package/.MainActivity")
    Check ([bool]($launch -match '^Status: ok$')) 'Release did not start.'
    Start-Sleep -Seconds 2
    Check ((Ui 'stage5-release-fresh').OuterXml -match 'My projects&#10;9|My projects&#xA;9') 'Fresh release default count incorrect.'
    foreach($kind in @('v0','v1','future')){
        Adb @('push',(Join-Path $evidence "stage5-$kind.moneybak"),"/sdcard/Download/QA_stage5_$kind.moneybak") | Out-Null
    }
    Data-Page
    Import-Preview 'QA_stage5_v0.moneybak'
    $preview=Ui 'stage5-v0-preview-release'
    Check ($preview.OuterXml -match 'v0.0' -and $preview.OuterXml -match 'no checksum') 'Legacy source version/integrity warning missing.'
    Shot 'v0-preview-release'
    Confirm-Restore
    Export-Verified $paths.a
    Equal-Fields 'stage5-v1.moneybak' $paths.a 'unsigned v0.0 -> release SAF restore -> signed v1 export'
    Import-Preview 'QA_stage5_v1.moneybak'
    Confirm-Restore
    Export-Verified $paths.b
    Equal-Fields $paths.a $paths.b 'stage4 v1 remains restorable in stage5 release'
    Top; Click '^匯入還原'; Open-Document 'QA_stage5_future.moneybak'
    $future=Ui 'stage5-future-rejected-release'
    Check ($future.OuterXml -match '先升級本應用程式' -and $future.OuterXml -match '目前資料未變更') 'Future version did not advise upgrade.'
    Click '^完成$'
    Top; Click '^匯入還原'; Back
    Export-Verified $paths.unchanged
    Equal-Fields $paths.b $paths.unchanged 'future-version rejection and picker cancel leave all data unchanged'
    # Release FileProvider/URI grant and sharesheet are tested with minification.
    Click '^分享檔案$'
    Check ((Ui 'stage5-share-release').OuterXml -match 'com.android.intentresolver') 'Release sharesheet missing.'
    Shot 'share-release'
    Back
    Adb @('shell','am','force-stop',$package) | Out-Null
    Adb @('install','-r',$apk) | Write-Output
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    Data-Page; Export-Verified $paths.upgrade
    Equal-Fields $paths.b $paths.upgrade 'same persistent release signing install -r and cold restart retain all data'
    Click '^恢復原廠設定$'; Click '^取消$'
    Click '^恢復原廠設定$'; Click '^確認清空$'
    for($i=0;$i -lt 12;$i++){
        $reset=Ui 'stage5-release-reset'
        if($reset.OuterXml -match 'Factory reset complete'){break}
    }
    Check ($reset.OuterXml -match 'Factory reset complete') 'Release reset did not complete.'
    Click '^Done$'
    Export-Verified $paths.zero
    $zero=Get-Content (Join-Path $evidence $paths.zero) -Raw | ConvertFrom-Json -AsHashtable
    Check ($zero.data.projects.Count -eq 9 -and $zero.data.bills.Count -eq 0 -and $zero.data.memos.Count -eq 0 -and $zero.data.editHistory.Count -eq 0 -and $zero.data.projectEntries.Count -eq 0) 'Final release reset counts wrong.'
    Check (@($zero.data.balanceRecords | Where-Object { $_.balanceMinor -ne 0 }).Count -eq 0) 'Nonzero default balance.'
    Check ((Ui 'stage5-release-no-copy').OuterXml -match 'No before-restore copy') 'Private copy remained after reset.'
    Adb @('shell','ls',"/sdcard/Download/$($paths.a)") | Out-Null
    Back; Back; Top; Shot 'release-final-home-zero'
    $paths | ConvertTo-Json | Set-Content (Join-Path $evidence 'stage5-native-paths.json') -Encoding utf8
    Write-Output 'PASS: signed release real files, v0.0/v1 compatibility, future rejection/cancel, sharesheet, install-r persistence and factory reset. QA left with zero defaults.'
} finally { Stop-Transcript | Out-Null }
