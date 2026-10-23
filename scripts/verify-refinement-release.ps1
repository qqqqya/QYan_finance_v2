# Destructive fixture setup is restricted by the imported QA AVD guard.
# Never point this script at a user's phone or original emulator.
param([switch]$FinalOnly)
. "$PSScriptRoot\stage5-ui-helpers.ps1"
$shots = Join-Path $projectRoot 'artifacts\screenshots\refinement'
New-Item -ItemType Directory -Path $shots -Force | Out-Null
$logName=if($FinalOnly){'refinement-final-release-native.txt'}else{'refinement-release-native.txt'}
Start-Transcript (Join-Path $evidence $logName) -UseMinimalHeader -Force | Out-Null
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss')
$paths = @{before="QA_refine_before_$stamp.moneybak";after="QA_refine_after_$stamp.moneybak";
    v0="QA_refine_v0_$stamp.moneybak";v2="QA_refine_v2_$stamp.moneybak";
    unchanged="QA_refine_unchanged_$stamp.moneybak";restart="QA_refine_restart_$stamp.moneybak";
    zero="QA_refine_zero_$stamp.moneybak"}
function Ui([string]$Name = 'refinement-native-current') {
    Adb @('shell','uiautomator','dump','/sdcard/finance-refine-ui.xml') | Out-Null
    $path=Join-Path $evidence "$Name.xml"
    Adb @('pull','/sdcard/finance-refine-ui.xml',$path) | Out-Null
    return [xml](Get-Content -LiteralPath $path -Raw -Encoding utf8)
}
function Open-Document([string]$FileName) {
    # The provider remembers scroll position. Search is independent of prior
    # visits, grid/list mode, file count and the pushed fixture's timestamp.
    $tree=Ui
    $search=@($tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('resource-id') -eq 'com.android.documentsui:id/option_menu_search'})
    if($search.Count){
        $p=Point $search[0]; Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
        $tree=Ui
    }
    $fields=@($tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('resource-id') -match ':id/search_src_text$' -or $_.GetAttribute('class') -eq 'android.widget.EditText'})
    if(!$fields.Count){throw 'System document search field missing.'}
    $field=$fields[0]; $p=Point $field
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    $oldText=$field.GetAttribute('text')
    Adb @('shell','input','keyevent','123') | Out-Null
    if($oldText.Length){ Adb (@('shell','input','keyevent') + (@('67') * $oldText.Length)) | Out-Null }
    Adb @('shell','input','text',$FileName) | Out-Null
    Adb @('shell','input','keyevent','66') | Out-Null
    for($i=0;$i -lt 8;$i++){
        $tree=Ui
        $nodes=@($tree.SelectNodes('//node') | Where-Object {$_.GetAttribute('text') -eq $FileName -and $_.GetAttribute('resource-id') -eq 'android:id/title'})
        if($nodes.Count){
            $p=Point $nodes[0]; Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
            Start-Sleep -Seconds 1
            return
        }
    }
    throw "SAF search did not find $FileName"
}
function Equal-Fields([string]$Left,[string]$Right,[switch]$Legacy){
    $code = 'import json,sys; a=json.load(open(sys.argv[1],encoding="utf-8-sig"))["data"]; b=json.load(open(sys.argv[2],encoding="utf-8-sig"))["data"]; a["settings"].update({"themeColor":"blue"}) if sys.argv[3]=="legacy" else None; assert json.dumps(a,sort_keys=True,ensure_ascii=False)==json.dumps(b,sort_keys=True,ensure_ascii=False), "Backup fields differ"; print("PASS: all fields equal" )'
    & python -c $code (Join-Path $evidence $Left) (Join-Path $evidence $Right) $(if($Legacy){'legacy'}else{'exact'})
    if($LASTEXITCODE -ne 0){throw 'Backup field comparison failed.'}
}
try {
    foreach($item in @(@('v0.0-all-types','v0'),@('v1-stage4-all-types','v1'),@('v2-theme-all-types','v2'))){
        Adb @('push',(Join-Path $projectRoot "test\fixtures\backups\$($item[0]).json"),"/sdcard/Download/QA_refine_$($item[1]).moneybak") | Out-Null
    }
    Adb @('push',(Join-Path $evidence 'refinement-future.moneybak'),'/sdcard/Download/QA_refine_future.moneybak') | Out-Null
    $installed=& $adbExe -s $device shell pm path $package 2>$null
    if($installed -match '^package:'){ Adb @('uninstall',$package) | Write-Output }
    $initialApk=if($FinalOnly){'finance-0.5.1-release.apk'}else{'finance-stage5-release.apk'}
    Adb @('install',(Join-Path $projectRoot "artifacts\$initialApk")) | Write-Output
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    Data-Page
    if(!$FinalOnly){
    Import-Preview 'QA_refine_v1.moneybak'; Confirm-Restore
    Export-Verified $paths.before
    Adb @('shell','am','force-stop',$package) | Out-Null
    Adb @('install','-r',(Join-Path $projectRoot 'artifacts\finance-0.5.1-release.apk')) | Write-Output
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    Data-Page; Export-Verified $paths.after
    Equal-Fields $paths.before $paths.after -Legacy
    Write-Output 'PASS: same persistent certificate stage5 -> 0.5.1 install-r and SQLite 2 -> 3 preserve all existing fields/order/settings; only themeColor=blue is added.'
    Import-Preview 'QA_refine_v0.moneybak'
    Check ((Ui 'refinement-v0-preview').OuterXml -match 'v0.0.*v2') 'Legacy migration preview does not identify v0.0 -> v2.'
    Confirm-Restore; Export-Verified $paths.v0
    Equal-Fields $paths.after $paths.v0
    } else {
        foreach($key in @('before','after','v0')){$paths.Remove($key)}
    }
    Import-Preview 'QA_refine_v2.moneybak'; Confirm-Restore; Export-Verified $paths.v2
    $fixture = Join-Path $evidence 'refinement-v2-fixture.json'
    Copy-Item -LiteralPath (Join-Path $projectRoot 'test\fixtures\backups\v2-theme-all-types.json') -Destination $fixture -Force
    Equal-Fields 'refinement-v2-fixture.json' $paths.v2
    Top; Click '^(Import & restore|匯入還原|导入恢复)'; Open-Document 'QA_refine_future.moneybak'
    Check ((Ui 'refinement-future-rejected').OuterXml -match '先升級本應用程式') 'Future format did not advise upgrade.'
    Click '^(Done|完成)$'; Export-Verified $paths.unchanged
    Equal-Fields $paths.v2 $paths.unchanged
    Adb @('shell','am','force-stop',$package) | Out-Null
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    Data-Page; Export-Verified $paths.restart
    Equal-Fields $paths.v2 $paths.restart
    Back; Back; Top; Shot 'purple-dark-home'
    Click '^月度帳單$'; Shot 'bills-entry-purple-dark'
    Click '^年度彙總$'; Shot 'annual-purple-dark'; Back
    Click '^記一筆$'; Shot 'bill-options-purple-dark'; Back
    Back; Top
    Click '^項目操作'; Shot 'project-menu-purple-dark'; Back
    Data-Page; Click '^(Factory reset|恢復原廠設定|恢复出厂设置)$'; Click '^(Clear and reset|確認清空|确认清空)$'
    for($i=0;$i -lt 12;$i++){ $tree=Ui; if($tree.OuterXml -match 'Factory reset complete'){break} }
    Check ($tree.OuterXml -match 'Factory reset complete') 'Factory reset missing.'
    Click '^Done$'; Export-Verified $paths.zero
    $zero=Get-Content (Join-Path $evidence $paths.zero) -Raw | ConvertFrom-Json -AsHashtable
    $ordered=@($zero.data.projects | Sort-Object sortOrder)
    Check ($ordered.Count -eq 9 -and $ordered[0].nameKey -eq 'largeExpense' -and $ordered[1].nameKey -eq 'liability') 'Fresh/default project order incorrect.'
    Check (@($zero.data.balanceRecords | Where-Object {$_.balanceMinor -ne 0}).Count -eq 0) 'Default balances nonzero.'
    Check ($zero.schemaVersion -eq 2 -and $zero.data.settings.themeColor -eq 'blue') 'Default v2 settings wrong.'
    Back; Back; Top; Shot 'blue-system-home-zero'
    $pathsName=if($FinalOnly){'refinement-final-native-paths.json'}else{'refinement-native-paths.json'}
    $paths | ConvertTo-Json | Set-Content (Join-Path $evidence $pathsName) -Encoding utf8
    Write-Output 'PASS: actual release URI recovery/export, future rejection, cold restart and zero default order. Original user emulator untouched.'
} finally { Stop-Transcript | Out-Null }
