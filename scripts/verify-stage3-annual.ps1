. "$PSScriptRoot\android-ui-helpers.ps1"
Check ((Adb @('emu','avd','name')) -contains 'Finance_API_36') 'Only Finance_API_36 is allowed.'
Start-Transcript -LiteralPath (Join-Path $evidence 'stage3-annual-final.txt') -UseMinimalHeader -Force | Out-Null
try {
    Adb @('shell','am','force-stop',$package) | Out-Null
    $launch = Adb @('shell','am','start','-W','-n',"$package/.MainActivity")
    Check ([bool]($launch -match '^Status: ok$')) 'Cold start did not report ok.'
    Click '^(系统设置|Settings)$'; Click '^English$'; Click '^Light$'; Back
    Click '^Monthly bills$'; Click '^Add transaction$'
    Input-Field '^Amount$' '12.34'
    Top; Click '^Category'; Click '^Food$'
    Input-Field '^Note$' 'QA_ANNUAL_AXIS'
    Click '^Save$'; Top; Click '^Annual summary$'
    Shot 'annual-light'; Back
    Click '^Food'; Click '^Delete$'; Click '^Delete$'
    Top
    Check ((Ui 'stage3-annual-cleared').OuterXml -match 'No transactions in this selection.') 'Final bill cleanup failed.'
    Back; Click '^Settings$'; Click '^Light$'; Click '^简体中文$'; Back
    Top; Shot 'home-zh-light'
    $finalState = Ui 'stage3-final-home'
    $labels = @($finalState.SelectNodes('//node') | ForEach-Object {$_.GetAttribute('content-desc')})
    Check ([bool]($labels -match '^我的项目\s+9$')) 'Expected 9 default projects.'
    Check ([bool]($labels -match '^总资产\s+CNY 0.00')) 'Expected zero totals.'
    Check (-not [bool]($labels -match 'QA_')) 'QA data left on home.'
    Write-Output 'PASS: latest APK annual axis screenshot checked with a real transaction; deleted it and restored Chinese light home with 9 zero projects.'
} finally { Stop-Transcript | Out-Null }
