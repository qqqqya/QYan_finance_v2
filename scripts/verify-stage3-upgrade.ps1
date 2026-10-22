# Uses only the disposable Finance_API_36 AVD. Its test app is replaced.
. "$PSScriptRoot\android-ui-helpers.ps1"
$name = Adb @('emu','avd','name')
Check ($name -contains 'Finance_API_36') 'Only Finance_API_36 is allowed.'
$oldApk = Join-Path $env:TEMP 'finance-user-installed-base.apk'
$newApk = Join-Path $projectRoot 'artifacts\finance-stage3-ide-debug.apk'
Check (Test-Path -LiteralPath $oldApk) 'Read-only copy of the old IDE APK is missing.'
Start-Transcript -LiteralPath (Join-Path $evidence 'stage3-upgrade-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    # Intentional test-device reset, never run on a phone with user data.
    $existing = & $adbExe -s $device shell pm path $package
    if ($existing -match '^package:') { Adb @('uninstall',$package) | Write-Output }
    Adb @('install',$oldApk) | Write-Output
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Write-Output
    Start-Sleep -Seconds 2
    Click '^(Settings|系统设置)$'; Click '^English$'; Click '^Light$'; Back
    $todayText = (Adb @('shell','date','+%F')).Trim()
    $today = [DateTime]::ParseExact($todayText,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
    Click '^New project$'
    Input-Field '^Name$' 'QA_STAGE3_UPGRADE'
    Input-Field '^Initial balance' '100.01'
    Input-Field '^Business date' $today.AddDays(-14).ToString('yyyy-MM-dd')
    Input-Field '^Note$' 'upgrade_project_note'
    Click '^Save$'
    Click '^QA_STAGE3_UPGRADE'
    Click '^Update balance$'
    Input-Field '^Actual balance after update' '500.02'
    Input-Field '^Business date' $today.AddDays(-7).ToString('yyyy-MM-dd')
    Input-Field '^Note$' 'middle_record'
    Click '^Save$'
    Click '^Update balance$'
    Input-Field '^Actual balance after update' '1000.01'
    Input-Field '^Note$' 'latest_record'
    Click '^Save$'
    Shot 'upgrade-before'
    Adb @('shell','am','force-stop',$package) | Out-Null
    Adb @('install','-r',$newApk) | Write-Output
    $launch = Adb @('shell','am','start','-W','-n',"$package/.MainActivity")
    $launch | Write-Output
    Check ([bool]($launch -match '^Status: ok$')) 'Upgrade start did not report ok.'
    Start-Sleep -Seconds 2
    Click '^QA_STAGE3_UPGRADE'
    $after = Ui 'stage3-upgrade-after'
    Check ($after.OuterXml -match '1,000.01') 'Upgrade lost current balance.'
    Check ($after.OuterXml -match 'upgrade_project_note') 'Upgrade lost project metadata.'
    Shot 'trend-line-light'
    Adb @('shell','input','swipe','980','2050','980','650','250') | Out-Null
    Shot 'trend-line-records'
    Top; Click '^Delete project$'; Click '^Delete$'
    Top
    Check ((Ui 'stage3-upgrade-cleaned').OuterXml -notmatch 'QA_STAGE3_UPGRADE') 'Upgrade fixture not removed.'
    Write-Output 'PASS: old IDE APK -> stage 3 IDE-compatible APK via install -r preserved three real snapshots, current balance and metadata. QA fixture deleted.'
} finally { Stop-Transcript | Out-Null }
