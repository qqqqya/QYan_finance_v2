# Mutating QA flow: restricted to the project's disposable AVD.
. "$PSScriptRoot\environment.ps1"
$adbExe = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$device = 'emulator-5560'
$package = 'com.example.finance_app'
$evidence = Join-Path $projectRoot 'artifacts\verification'
$shots = Join-Path $projectRoot 'artifacts\screenshots\stage3'
New-Item -ItemType Directory -Path $shots -Force | Out-Null
function Adb([string[]]$Command) {
    $value = & $adbExe -s $device @Command 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $value" }
    return $value
}
function Ui([string]$Name = 'stage3-native-current') {
    Adb @('shell','uiautomator','dump','/sdcard/finance3-ui.xml') | Out-Null
    $path = Join-Path $evidence "$Name.xml"
    Adb @('pull','/sdcard/finance3-ui.xml',$path) | Out-Null
    return [xml](Get-Content -LiteralPath $path -Raw -Encoding utf8)
}
function Top {
    for ($i=0; $i -lt 5; $i++) { Adb @('shell','input','swipe','980','600','980','2100','120') | Out-Null }
}
function Point($Node) {
    $m = [regex]::Match($Node.GetAttribute('bounds'),'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    return @([int](([int]$m.Groups[1].Value+[int]$m.Groups[3].Value)/2),
        [int](([int]$m.Groups[2].Value+[int]$m.Groups[4].Value)/2))
}
function Seek([string]$Pattern,[switch]$Field) {
    for ($i=0; $i -lt 15; $i++) {
        $tree = Ui
        $nodes = @($tree.SelectNodes('//node') | Where-Object {
            $_.GetAttribute('package') -eq $package -and
            $(if ($Field) { $_.GetAttribute('class') -eq 'android.widget.EditText' -and $_.GetAttribute('hint') -match $Pattern }
              else { $_.GetAttribute('clickable') -eq 'true' -and $_.GetAttribute('content-desc') -match $Pattern })
        })
        if ($nodes.Count -gt 0) { return $nodes[0] }
        Adb @('shell','input','swipe','980','2050','980','650','200') | Out-Null
    }
    throw "Native control missing: $Pattern"
}
function Click([string]$Pattern) {
    $p = Point (Seek $Pattern)
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    Start-Sleep -Milliseconds 350
}
function Input-Field([string]$Pattern,[string]$Value) {
    $field = Seek $Pattern -Field
    $oldText = $field.GetAttribute('text')
    $p = Point $field
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    Start-Sleep -Milliseconds 200
    Adb @('shell','input','keyevent','123') | Out-Null
    if ($oldText.Length -gt 0) {
        Adb (@('shell','input','keyevent') + (@('67') * $oldText.Length)) | Out-Null
    }
    Adb @('shell','input','text',$Value.Replace(' ','%s')) | Out-Null
    Adb @('shell','input','keyevent','4') | Out-Null
    Start-Sleep -Milliseconds 300
    $entered = (Seek $Pattern -Field).GetAttribute('text')
    Check ($entered -eq $Value) "Native input mismatch for $Pattern"
}
function Shot([string]$Name) {
    Adb @('shell','screencap','-p','/sdcard/finance3.png') | Out-Null
    Adb @('pull','/sdcard/finance3.png',(Join-Path $shots "$Name.png")) | Out-Null
}
function Check([bool]$Ok,[string]$Message) { if (-not $Ok) { throw $Message } }
function Back { Adb @('shell','input','keyevent','4') | Out-Null; Start-Sleep -Milliseconds 500 }
function Restart {
    $before = (Adb @('shell','pidof',$package)).Trim()
    Adb @('shell','am','force-stop',$package) | Out-Null
    $launch = Adb @('shell','am','start','-W','-n',"$package/.MainActivity")
    Check ([bool]($launch -match '^Status: ok$')) 'Cold start did not report ok.'
    Start-Sleep -Seconds 2
    $after = (Adb @('shell','pidof',$package)).Trim()
    Check ($before -ne $after) 'Process did not change.'
    Write-Output "Cold restart PID $before -> $after"
}
