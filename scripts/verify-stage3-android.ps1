. "$PSScriptRoot\android-ui-helpers.ps1"
$name = Adb @('emu','avd','name')
Check ($name -contains 'Finance_API_36') 'Only Finance_API_36 is allowed for this mutating script.'
Start-Transcript -LiteralPath (Join-Path $evidence 'stage3-android-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    Adb @('shell','am','force-stop',$package) | Out-Null
    $launch = Adb @('shell','am','start','-W','-n',"$package/.MainActivity")
    Check ([bool]($launch -match '^Status: ok$')) 'Start did not report ok.'
    Start-Sleep -Seconds 2
    Click '^(系统设置|系統設定|Settings)$'
    Click '^English$'; Click '^Light$'; Back
    # Bill and memo content are entered through Android's real text fields.
    Click '^Monthly bills$'
    Click '^Previous month$'
    $monthUi = Ui 'stage3-selected-month'
    Click '^Add transaction$'
    Input-Field '^Amount$' '12.34'
    Top; Click '^Category'; Click '^Food$'
    Input-Field '^Note$' 'QA_NATIVE_BILL_PERSIST'
    Click '^Save$'
    Top; Shot 'bills-light'
    Click '^Annual summary$'; Top; Shot 'annual-light'; Back
    Restart
    Click '^Monthly bills$'; Click '^Previous month$'
    $restored = Ui 'stage3-bill-restarted'
    # Ensure list row is built even when it starts below the chart.
    Click '^Food'
    $billEditor = Ui 'stage3-bill-editor-restarted'
    Check ($billEditor.OuterXml -match '12.34') 'Bill cents were not retained.'
    Seek '^Note$' -Field | Out-Null
    Check ((Ui 'stage3-bill-note-restarted').OuterXml -match 'QA_NATIVE_BILL_PERSIST') 'Bill note was not retained.'
    Write-Output 'PASS: ordinary APK bill amount/note survive force-stop and cold restart.'
    Back; Back
    Click '^Finance memos$'; Click '^New memo$'
    Input-Field '^Title$' 'QA_NATIVE_MEMO'
    Input-Field '^Text$' 'persisted_memo_body'
    Input-Field '^Tags$' 'native, persistence'
    Click '^Save$'; Top; Shot 'memos-light'
    Restart
    Click '^Finance memos$'; Click '^QA_NATIVE_MEMO'
    $memoEditor = Ui 'stage3-memo-restarted'
    Check ($memoEditor.OuterXml -match 'persisted_memo_body') 'Memo body was not retained.'
    Seek '^Tags$' -Field | Out-Null
    Check ((Ui 'stage3-memo-tags-restarted').OuterXml -match 'persistence') 'Memo tags were not retained.'
    Write-Output 'PASS: ordinary APK memo title/body/tags survive force-stop and cold restart.'
    Top; Input-Field '^Title$' 'UNSAVED_QA'
    # First Back may close IME; later Back must show the unsaved guard.
    for ($i=0; $i -lt 3; $i++) { Back; if ((Ui).OuterXml -match 'Unsaved changes') { break } }
    Check ((Ui 'stage3-unsaved-back').OuterXml -match 'Unsaved changes') 'Unsaved memo Back did not guard changes.'
    Click '^Keep editing$'; Back
    if ((Ui).OuterXml -notmatch 'Unsaved changes') { Back }
    Click '^Discard$'
    Click '^QA_NATIVE_MEMO'; Click '^Delete$'; Click '^Delete$'; Back
    Click '^Monthly bills$'; Click '^Previous month$'; Click '^Food'; Click '^Delete$'; Click '^Delete$'
    Top; Check ((Ui 'stage3-after-delete').OuterXml -notmatch 'QA_NATIVE_BILL_PERSIST') 'Bill was not deleted.'
    Back
    Click '^Settings$'; Click '^Dark$'; Back
    Click '^Monthly bills$'; Shot 'bills-dark'
    # Edge gesture must return to the app home, not the launcher.
    Adb @('shell','input','swipe','1','1000','450','1000','450') | Out-Null
    Start-Sleep -Milliseconds 700
    Check ((Ui 'stage3-edge-back').OuterXml -match 'My projects') 'Left edge did not return to home.'
    Click '^Settings$'; Click '^Light$'; Click '^简体中文$'; Back
    Top; Shot 'home-zh-light'
    Write-Output 'PASS: memo unsaved guard, deletion, native edge return and dark/light pages; QA records removed.'
} finally { Stop-Transcript | Out-Null }
