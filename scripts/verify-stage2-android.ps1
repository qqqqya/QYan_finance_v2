param([string]$Device = 'emulator-5560', [switch]$ResumeExistingFixture)
. "$PSScriptRoot\environment.ps1"
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$evidence = Join-Path $projectRoot 'artifacts\verification'
$shots = Join-Path $projectRoot 'artifacts\screenshots\stage2'
New-Item -ItemType Directory -Path $shots -Force | Out-Null
$package = 'com.example.finance_app'
$testName = 'QA_STAGE2_PERSISTENCE'
function Adb([string[]]$Command) {
    $result = & $adb -s $Device @Command 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $result" }
    return $result
}
function Ui([string]$Name = 'stage2-native-current') {
    Adb @('shell','uiautomator','dump','/sdcard/finance2-ui.xml') | Out-Null
    $path = Join-Path $evidence "$Name.xml"
    Adb @('pull','/sdcard/finance2-ui.xml',$path) | Out-Null
    return [xml](Get-Content -LiteralPath $path -Raw -Encoding utf8)
}
function Bounds($Node) {
    $match = [regex]::Match($Node.GetAttribute('bounds'), '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    return @([int](($match.Groups[1].Value -as [int]) + (($match.Groups[3].Value -as [int]) - ($match.Groups[1].Value -as [int]))/2),
      [int](($match.Groups[2].Value -as [int]) + (($match.Groups[4].Value -as [int]) - ($match.Groups[2].Value -as [int]))/2))
}
function Seek([string]$Pattern, [switch]$Field) {
    for ($attempt = 0; $attempt -lt 14; $attempt++) {
        $tree = Ui
        $nodes = @($tree.SelectNodes('//node') | Where-Object {
            $_.GetAttribute('package') -eq $package -and
            $(if ($Field) { $_.GetAttribute('class') -eq 'android.widget.EditText' -and $_.GetAttribute('hint') -match $Pattern }
              else { $_.GetAttribute('content-desc') -match $Pattern -and $_.GetAttribute('clickable') -eq 'true' })
        })
        if ($nodes.Count -gt 0) { return $nodes[0] }
        Adb @('shell','input','swipe','940','2050','940','650','350') | Out-Null
    }
    throw "Visible native control missing: $Pattern"
}
function Click([string]$Pattern) {
    $point = Bounds (Seek $Pattern)
    Adb @('shell','input','tap',"$($point[0])","$($point[1])") | Out-Null
    Start-Sleep -Milliseconds 450
}
function Input-Field([string]$Pattern, [string]$Value) {
    $point = Bounds (Seek $Pattern -Field)
    Adb @('shell','input','tap',"$($point[0])","$($point[1])") | Out-Null
    Start-Sleep -Milliseconds 400
    Adb @('shell','input','keycombination','113','29') | Out-Null
    Adb @('shell','input','text',$Value) | Out-Null
    Adb @('shell','input','keyevent','4') | Out-Null
    Start-Sleep -Milliseconds 350
}
function Top {
    for ($i = 0; $i -lt 5; $i++) {
        Adb @('shell','input','swipe','950','650','950','2100','150') | Out-Null
    }
}
function Screenshot([string]$Name) {
    Adb @('shell','screencap','-p','/sdcard/finance2.png') | Out-Null
    Adb @('pull','/sdcard/finance2.png',(Join-Path $shots "$Name.png")) | Out-Null
}
function Check([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Restart {
    $before = (Adb @('shell','pidof',$package)).Trim()
    Adb @('shell','am','force-stop',$package) | Out-Null
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    $after = (Adb @('shell','pidof',$package)).Trim()
    Check ($before -ne $after) 'Process did not restart.'
    Write-Output "Process restarted: $before -> $after"
}
function Bank-Nodes {
    $tree = Ui
    return @($tree.SelectNodes('//node') | Where-Object {
        $_.GetAttribute('content-desc') -match '^(China Merchants Bank|Bank of Communications)\n' -and
        $_.GetAttribute('clickable') -eq 'true'
    })
}
function Drag-Cards([int[]]$One, [int[]]$Two) {
    Adb @('shell','input','motionevent','DOWN',"$($One[0])","$($One[1])") | Out-Null
    Start-Sleep -Milliseconds 1000
    Adb @('shell','input','motionevent','MOVE',"$($Two[0])","$($Two[1])") | Out-Null
    Start-Sleep -Milliseconds 350
    Adb @('shell','input','motionevent','UP',"$($Two[0])","$($Two[1])") | Out-Null
    Start-Sleep -Milliseconds 600
}
function Unsaved-Dialog {
    # Android Back first closes an open IME. Restored form focus may reopen it.
    for ($i=0; $i -lt 3; $i++) {
        Adb @('shell','input','keyevent','4') | Out-Null
        if ((Ui 'stage2-unsaved-back').OuterXml -match 'Unsaved changes') { return }
    }
    throw 'Native Back skipped the unsaved-changes guard.'
}
Start-Transcript -LiteralPath (Join-Path $evidence 'stage2-android-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    Adb @('shell','am','force-stop',$package) | Out-Null
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    Adb @('shell','cmd','overlay','enable-exclusive','--category','com.android.internal.systemui.navbar.gestural') | Out-Null
    Start-Sleep -Seconds 1
    Click '^(Settings|系统设置|系統設定)$'
    Click '^(Light|浅色|淺色)$'
    Click '^English$'
    Adb @('shell','input','keyevent','4') | Out-Null
    if (-not $ResumeExistingFixture) {
        Click '^New project$'
        Input-Field '^Name$' $testName
        Input-Field '^Initial balance' '12.34'
        Input-Field '^Note$' 'persisted_project_note'
        Click '^Save$'
        Click ('^' + $testName + '\n')
        Check ((Ui).OuterXml -match '¥12.34') 'Initial amount was not saved.'
        Click '^Update balance$'
        Input-Field '^Actual balance' '56.78'
        Input-Field '^Note$' 'persisted_record_note'
        Click '^Save$'
    } else { Click ('^' + $testName + '\n') }
    Top
    Check ((Ui 'stage2-detail-before-restart').OuterXml -match '¥56.78') 'Updated balance was not visible.'
    Screenshot 'detail-light-before-restart'
    Restart
    Click ('^' + $testName + '\n')
    $tree = Ui 'stage2-detail-after-restart'
    Check ($tree.OuterXml -match '¥56.78' -and $tree.OuterXml -match 'persisted_project_note') 'Balance/project note did not survive.'
    for ($i=0; $i -lt 5; $i++) {
        $tree = Ui
        if ($tree.OuterXml -match 'persisted_record_note') { break }
        Adb @('shell','input','swipe','950','2050','950','700','250') | Out-Null
    }
    Check ($tree.OuterXml -match 'persisted_record_note') 'Record note did not survive.'
    Ui 'stage2-records-after-restart' | Out-Null
    Write-Output 'PASS T21: real process restart preserved the initial/latest snapshots and project/record notes.'
    Top
    Click '^Update balance$'
    Input-Field '^Actual balance' '11.11'
    Unsaved-Dialog
    Click '^Keep editing$'
    Unsaved-Dialog
    Click '^Discard$'
    Check ((Ui).OuterXml -match '¥56.78') 'Discard changed the saved balance.'
    Write-Output 'PASS: native Back can keep editing or discard without changing the saved amount.'
    Adb @('shell','input','swipe','2','1200','400','1200','350') | Out-Null
    Check ((Ui).OuterXml -match 'Finances') 'Left-edge gesture did not return to home.'
    Top
    $banks = @(Bank-Nodes)
    Check ($banks.Count -eq 2) 'Default bank cards were not visible.'
    $one = Bounds $banks[0]; $two = Bounds $banks[1]
    Drag-Cards $one $two
    Start-Sleep -Milliseconds 700
    $afterDrop = @(Bank-Nodes)
    Check ($afterDrop[0].GetAttribute('content-desc') -match '^Bank of Communications') 'Native card drag failed.'
    Restart
    Top
    $afterRestart = @(Bank-Nodes)
    Check ($afterRestart[0].GetAttribute('content-desc') -match '^Bank of Communications') 'Card order did not persist.'
    Ui 'stage2-order-after-restart' | Out-Null
    Write-Output 'PASS T11/T21: injected Android long press/drop persisted the grid order after force-stop.'
    # Restore the two moved default cards; this script leaves no financial QA fixture.
    $one = Bounds $afterRestart[0]; $two = Bounds $afterRestart[1]
    Drag-Cards $one $two
    Top
    Click '^Total assets\n'
    Screenshot 'overview-light'
    for ($i=0; $i -lt 3; $i++) { Adb @('shell','input','swipe','950','2000','950','900','250') | Out-Null }
    Screenshot 'trend-light'
    Adb @('shell','input','keyevent','4') | Out-Null
    Top
    Click '^Settings$'; Click '^Dark$'
    Adb @('shell','input','keyevent','4') | Out-Null
    Click ('^' + $testName + '\n')
    Screenshot 'detail-dark'
    Adb @('shell','input','swipe','1078','1200','680','1200','350') | Out-Null
    Check ((Ui).OuterXml -match 'Finances') 'Right-edge gesture did not return to home.'
    Click ('^' + $testName + '\n')
    Click '^Delete project$'; Click '^Delete$'
    Top
    $homeState = Ui 'stage2-home-after-cleanup'
    Check ($homeState.OuterXml -match '¥0.00' -and $homeState.OuterXml -notmatch $testName) 'QA project cleanup failed.'
    Click '^Settings$'; Click '^Light$'; Click '^简体中文$'
    Adb @('shell','input','keyevent','4') | Out-Null
    Start-Sleep -Milliseconds 600
    Adb @('shell','input','keyevent','3') | Out-Null
    Adb @('shell','am','start','-W','-n',"$package/.MainActivity") | Out-Null
    $restored = Ui 'stage2-home-background-restore'
    Check ($restored.OuterXml -match '财管' -and $restored.OuterXml -match '¥0.00') 'Background restoration failed.'
    Screenshot 'home-zh-light'
    Write-Output 'PASS T01: zero home restored after background/foreground.'
    Write-Output 'PASS: both native detail back gestures, dark/light pages and fixture deletion. No QA financial data remains.'
} finally { Stop-Transcript | Out-Null }
