# Ordinary APK, real Android input/IME, only the disposable QA emulator.
. "$PSScriptRoot\stage5-ui-helpers.ps1"
$font = (Adb @('shell','settings','get','system','font_scale')).Trim()
$rotation = (Adb @('shell','settings','get','system','user_rotation')).Trim()
$auto = (Adb @('shell','settings','get','system','accelerometer_rotation')).Trim()
$night = ((Adb @('shell','cmd','uimode','night')) -join '').Split(':')[-1].Trim()
Start-Transcript (Join-Path $evidence 'stage5-navigation-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    Click '^(Settings|系统设置|系統設定)$'; Click '^English$'; Click '^Light$'; Back
    Click '^Monthly bills$'
    Adb @('shell','input','swipe','300','1000','650','1000','450') | Out-Null
    $interior=Ui 'stage5-interior-swipe'
    Check ($interior.OuterXml -match 'Monthly bills' -and $interior.OuterXml -notmatch 'My projects') 'Interior swipe popped route.'
    Adb @('shell','input','swipe','1','1000','450','1000','450') | Out-Null
    Check ((Ui 'stage5-left-back').OuterXml -match 'My projects') 'Left edge return failed.'
    Click '^Monthly bills$'
    Adb @('shell','input','swipe','1079','1000','630','1000','450') | Out-Null
    Check ((Ui 'stage5-right-back').OuterXml -match 'My projects') 'Right edge return failed.'
    Click '^Monthly bills$'
    # The device's input help explicitly supports ACTION_CANCEL.
    Adb @('shell','input','motionevent','DOWN','1','1000') | Out-Null
    Adb @('shell','input','motionevent','MOVE','160','1000') | Out-Null
    Adb @('shell','input','motionevent','CANCEL','160','1000') | Out-Null
    Start-Sleep -Milliseconds 500
    $cancelled=Ui 'stage5-canceled-edge'
    Check ($cancelled.OuterXml -match 'Monthly bills' -and $cancelled.OuterXml -notmatch 'My projects') 'Canceled edge gesture popped route.'
    Back
    Check ((Ui 'stage5-back-after-cancel').OuterXml -match 'My projects') 'Back after canceled gesture did not return one level.'
    Click '^New project$'
    $p=Point (Seek '^Name$' -Field)
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    Adb @('shell','input','text','QA_UNSAVED_NATIVE') | Out-Null
    $ime=Adb @('shell','dumpsys','input_method')
    Check ([bool]($ime -match 'mInputShown=true|mIsInputViewShown=true')) 'Real IME was not shown.'
    Shot 'keyboard-project'
    Back
    $draft=Ui 'stage5-keyboard-back'
    Check ($draft.OuterXml -match 'QA_UNSAVED_NATIVE' -and $draft.OuterXml -notmatch 'Unsaved changes') 'First Back did not only close IME.'
    Back
    Check ((Ui 'stage5-unsaved-guard').OuterXml -match 'Unsaved changes') 'Dirty draft guard missing.'
    Click '^Keep editing$'
    Check ((Ui).OuterXml -match 'QA_UNSAVED_NATIVE') 'Keep editing lost draft.'
    for($i=0;$i -lt 3;$i++){
        Back
        if((Ui).OuterXml -match 'Unsaved changes'){break}
    }
    Click '^Discard$'
    Check ((Ui).OuterXml -match 'My projects') 'Discard did not return home.'
    Data-Page; Click '^Factory reset$'; Back
    Check ((Ui 'stage5-dialog-back').OuterXml -match 'Data management') 'Back dismissed the underlying page.'
    Back; Back; Back
    $focus=Adb @('shell','dumpsys','activity','activities')
    Check ([bool]($focus -match 'topResumedActivity=.*launcher')) 'Root Back did not follow the system launcher behavior.'
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 1
    Click '^Settings$'; Click '^Dark$'
    Adb @('shell','cmd','uimode','night','no') | Out-Null
    Back; Top; Shot 'manual-dark-system-light'
    Click '^Settings$'; Click '^Light$'
    Adb @('shell','cmd','uimode','night','yes') | Out-Null
    Back; Top; Shot 'manual-light-system-dark'
    Click '^Settings$'; Click '^Follow system$'; Back; Top; Shot 'follow-system-dark'
    Adb @('shell','cmd','uimode','night','no') | Out-Null
    Top; Shot 'follow-system-light'
    Click '^Settings$'; Click '^简体中文$'; Back; Top; Shot 'home-zh-Hans'
    Click '^系统设置$'; Click '^繁體中文$'; Back; Top; Shot 'home-zh-Hant'
    Click '^系統設定$'; Click '^English$'; Back
    foreach($case in @(@('480','1.0','360dp'),@('360','1.5','480dp-150'),@('540','2.0','320dp-200'))){
        Adb @('shell','wm','density',$case[0]) | Out-Null
        Adb @('shell','settings','put','system','font_scale',$case[1]) | Out-Null
        Start-Sleep -Milliseconds 500
        Top; Shot "home-$($case[2])"
    }
    Adb @('shell','settings','put','system','accelerometer_rotation','0') | Out-Null
    Adb @('shell','settings','put','system','user_rotation','1') | Out-Null
    Start-Sleep -Seconds 1
    Top; Shot 'home-landscape-200'
    Click '^Monthly bills$'
    $month=(Adb @('shell','date','+%Y-%m')).Trim()
    Click ("^"+$month+'$')
    Shot 'month-dialog-landscape-200'
    Back; Back
    Write-Output 'PASS: ordinary APK native left/right edge Back, interior swipe, canceled edge, IME-only first Back, dirty keep/discard, dialog Back, root launcher, locales/themes and emulator screen/rotation/font variants.'
} finally {
    Adb @('shell','wm','density','reset') | Out-Null
    Adb @('shell','settings','put','system','font_scale',$font) | Out-Null
    Adb @('shell','settings','put','system','accelerometer_rotation',$auto) | Out-Null
    Adb @('shell','settings','put','system','user_rotation',$rotation) | Out-Null
    if($night -in @('yes','no','auto')){Adb @('shell','cmd','uimode','night',$night) | Out-Null}
    Stop-Transcript | Out-Null
}
