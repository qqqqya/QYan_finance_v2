param([string]$Device = 'emulator-5560')

. "$PSScriptRoot\environment.ps1"
$adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$package = 'com.example.finance_app'
$evidence = Join-Path $projectRoot 'artifacts\verification'
$screenshots = Join-Path $projectRoot 'artifacts\screenshots'
New-Item -ItemType Directory -Path $evidence, $screenshots -Force | Out-Null

function Invoke-Adb([string[]]$Command) {
    $result = & $adb -s $Device @Command 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $($Command[0]) $result" }
    return $result
}

function Read-Ui([string]$Name = 'ui-current') {
    Invoke-Adb @('shell', 'uiautomator', 'dump', '/sdcard/finance-ui.xml') | Out-Null
    $localPath = Join-Path $evidence "$Name.xml"
    Invoke-Adb @('pull', '/sdcard/finance-ui.xml', $localPath) | Out-Null
    return [xml](Get-Content -LiteralPath $localPath -Raw -Encoding utf8)
}

function Find-Label($Ui, [string[]]$Labels, [switch]$Clickable) {
    return @($Ui.SelectNodes('//node') | Where-Object {
        $_.GetAttribute('content-desc') -in $Labels -and
        (-not $Clickable -or $_.GetAttribute('clickable') -eq 'true')
    })
}

function Tap-Label([string[]]$Labels) {
    $nodes = @(Find-Label (Read-Ui) $Labels -Clickable)
    if ($nodes.Count -eq 0) { throw "Visible control missing: $($Labels -join '/')" }
    $bounds = [regex]::Match($nodes[0].GetAttribute('bounds'), '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (-not $bounds.Success) { throw 'Invalid accessibility bounds.' }
    $tapX = [int](([int]$bounds.Groups[1].Value + [int]$bounds.Groups[3].Value) / 2)
    $tapY = [int](([int]$bounds.Groups[2].Value + [int]$bounds.Groups[4].Value) / 2)
    Invoke-Adb @('shell', 'input', 'tap', "$tapX", "$tapY") | Out-Null
    Start-Sleep -Milliseconds 350
}

function Assert-Label($Ui, [string[]]$Labels) {
    if (@(Find-Label $Ui $Labels).Count -eq 0) { throw "Screen missing: $($Labels -join '/')" }
}

function Assert-Checked($Ui, [string[]]$Labels) {
    if (-not ((Find-Label $Ui $Labels) | Where-Object { $_.GetAttribute('checked') -eq 'true' })) {
        throw "Saved selection missing: $($Labels -join '/')"
    }
}

function Assert-Home([string]$Name) {
    $ui = Read-Ui $Name
    Assert-Label $ui @('财管')
    if ($ui.OuterXml -notmatch '总资产' -or $ui.OuterXml -notmatch '¥0.00') {
        throw 'Zero-valued home was not visible.'
    }
    $activity = Invoke-Adb @('shell', 'dumpsys', 'activity', 'activities')
    if (($activity | Select-String 'topResumedActivity') -notmatch [regex]::Escape($package)) {
        throw 'The finance app is no longer in the foreground.'
    }
}

function Save-Screen([string]$Name) {
    Invoke-Adb @('shell', 'screencap', '-p', '/sdcard/finance-stage1.png') | Out-Null
    Invoke-Adb @('pull', '/sdcard/finance-stage1.png', (Join-Path $screenshots "$Name.png")) | Out-Null
}

Start-Transcript -LiteralPath (Join-Path $evidence 'stage1-android-native.txt') -UseMinimalHeader -Force | Out-Null
try {
    Write-Output "Device: $Device; package: $package"
    if ((Invoke-Adb @('shell', 'settings', 'get', 'secure', 'navigation_mode')).Trim() -ne '2') {
        throw 'Use Android system gesture navigation before running this check.'
    }
    $size = [regex]::Match((Invoke-Adb @('shell', 'wm', 'size')) -join ' ', '(\d+)x(\d+)')
    $width = [int]$size.Groups[1].Value
    $height = [int]$size.Groups[2].Value
    $middleY = [int]($height / 2)
    Invoke-Adb @('shell', 'am', 'force-stop', $package) | Out-Null
    Invoke-Adb @('shell', 'am', 'start', '-W', '-n', "$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2

    Tap-Label @('Settings', '系统设置', '系統設定')
    Tap-Label @('Dark', '深色')
    Tap-Label @('简体中文')
    $ui = Read-Ui 'ui-before-restart'
    Assert-Checked $ui @('深色')
    Assert-Checked $ui @('简体中文')
    Save-Screen 'settings-zh-dark-before-restart'
    $beforePid = (Invoke-Adb @('shell', 'pidof', $package)).Trim()
    Invoke-Adb @('shell', 'am', 'force-stop', $package) | Out-Null
    Invoke-Adb @('shell', 'am', 'start', '-W', '-n', "$package/.MainActivity") | Out-Null
    Start-Sleep -Seconds 2
    $afterPid = (Invoke-Adb @('shell', 'pidof', $package)).Trim()
    if ($beforePid -eq $afterPid) { throw 'The process did not restart.' }
    Assert-Home 'ui-home-after-restart'
    Save-Screen 'home-zh-dark-after-restart'
    Tap-Label @('系统设置')
    $ui = Read-Ui 'ui-after-restart'
    Assert-Checked $ui @('深色')
    Assert-Checked $ui @('简体中文')
    Write-Output "PASS: force-stop/restart ($beforePid -> $afterPid), language and dark selection persisted."

    Invoke-Adb @('shell', 'input', 'swipe', '2', "$middleY", '400', "$middleY", '350') | Out-Null
    Start-Sleep -Milliseconds 600
    Assert-Home 'ui-after-left-edge'
    Write-Output 'PASS: left-edge system gesture returned to home and kept the app foreground.'
    Tap-Label @('系统设置')
    Invoke-Adb @('shell', 'input', 'swipe', "$($width-2)", "$middleY", "$($width-400)", "$middleY", '350') | Out-Null
    Start-Sleep -Milliseconds 600
    Assert-Home 'ui-after-right-edge'
    Write-Output 'PASS: right-edge system gesture returned to home and kept the app foreground.'

    Tap-Label @('系统设置')
    Invoke-Adb @('shell', 'input', 'swipe', '300', "$middleY", '780', "$middleY", '350') | Out-Null
    Assert-Label (Read-Ui 'ui-after-center-swipe') @('系统设置')
    Write-Output 'PASS: ordinary horizontal swipe did not leave settings.'
    Invoke-Adb @('shell', 'input', 'motionevent', 'DOWN', '2', "$middleY") | Out-Null
    Invoke-Adb @('shell', 'input', 'motionevent', 'MOVE', '160', "$middleY") | Out-Null
    Invoke-Adb @('shell', 'input', 'motionevent', 'CANCEL', '160', "$middleY") | Out-Null
    Assert-Label (Read-Ui 'ui-after-cancel-event') @('系统设置')
    Write-Output 'PASS: injected edge motion cancellation kept settings visible.'
    Invoke-Adb @('shell', 'input', 'keyevent', '4') | Out-Null
    Assert-Home 'ui-after-back-key'
    Write-Output 'PASS: Android Back key returned to home.'

    Tap-Label @('系统设置')
    Tap-Label @('繁體中文')
    Assert-Label (Read-Ui 'ui-language-hant') @('系統設定')
    Save-Screen 'settings-hant-dark'
    Tap-Label @('English')
    Assert-Label (Read-Ui 'ui-language-en') @('Settings')
    Save-Screen 'settings-en-dark'
    Tap-Label @('简体中文')
    Assert-Label (Read-Ui 'ui-language-hans') @('系统设置')
    Tap-Label @('浅色')
    # A manually selected light theme must remain usable in Android night mode.
    Invoke-Adb @('shell', 'cmd', 'uimode', 'night', 'yes') | Out-Null
    Start-Sleep -Milliseconds 600
    Assert-Checked (Read-Ui 'ui-manual-light-system-dark') @('浅色')
    Save-Screen 'settings-zh-light-system-dark'
    Invoke-Adb @('shell', 'input', 'keyevent', '4') | Out-Null
    Assert-Home 'ui-home-final'
    Save-Screen 'home-zh-light'
    Write-Output 'PASS: three app languages rendered; final language is Simplified Chinese, manual theme is light.'
    Write-Output 'Native verification passed. Screenshots require separate visual review.'
} finally {
    Stop-Transcript | Out-Null
}
