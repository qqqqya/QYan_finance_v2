# Only the disposable Finance_API_36 AVD; never use this helper on a user phone.
. "$PSScriptRoot\android-ui-helpers.ps1"
Check ((Adb @('emu','avd','name')) -contains 'Finance_API_36') 'Only the QA AVD is allowed.'
$shots = Join-Path $projectRoot 'artifacts\screenshots\stage4'
New-Item -ItemType Directory -Path $shots -Force | Out-Null
function Ui([string]$Name = 'stage4-native-current') {
    Adb @('shell','uiautomator','dump','/sdcard/finance4-ui.xml') | Out-Null
    $path = Join-Path $evidence "$Name.xml"
    Adb @('pull','/sdcard/finance4-ui.xml',$path) | Out-Null
    return [xml](Get-Content -LiteralPath $path -Raw -Encoding utf8)
}
function SysNode([string]$Pattern) {
    $tree = Ui
    $nodes = @($tree.SelectNodes('//node') | Where-Object {
        $_.GetAttribute('text') -match $Pattern -or $_.GetAttribute('content-desc') -match $Pattern -or $_.GetAttribute('resource-id') -match $Pattern
    })
    if ($nodes.Count -eq 0) { throw "System control missing: $Pattern" }
    return $nodes[0]
}
function SysClick([string]$Pattern) {
    $p = Point (SysNode $Pattern)
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    Start-Sleep -Milliseconds 500
}
function Save-Document([string]$FileName) {
    $field = $null
    for ($i=0; $i -lt 15; $i++) {
        $tree = Ui
        $field = @($tree.SelectNodes('//node') | Where-Object { $_.GetAttribute('resource-id') -eq 'android:id/title' -and $_.GetAttribute('class') -eq 'android.widget.EditText' })[0]
        if ($null -ne $field) { break }
        Check ($tree.OuterXml -notmatch '(Operation not completed|操作未完成)') 'Export preparation failed.'
    }
    if ($null -eq $field) { throw 'SAF save filename field not found.' }
    $p = Point $field
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    Adb @('shell','input','keyevent','123') | Out-Null
    $old = $field.GetAttribute('text')
    Adb (@('shell','input','keyevent') + (@('67') * $old.Length)) | Out-Null
    Adb @('shell','input','text',$FileName) | Out-Null
    Back
    SysClick '^android:id/button1$'
}
function Open-Document([string]$FileName) {
    $nodes = @()
    for ($i=0; $i -lt 12; $i++) {
        $tree = Ui
        $nodes = @($tree.SelectNodes('//node') | Where-Object { $_.GetAttribute('text') -eq $FileName })
        if ($nodes.Count -gt 0) { break }
        Adb @('shell','input','swipe','980','2050','980','650','200') | Out-Null
    }
    if ($nodes.Count -eq 0) { throw "SAF file not found: $FileName" }
    $p = Point $nodes[0]
    Adb @('shell','input','tap',"$($p[0])","$($p[1])") | Out-Null
    Start-Sleep -Seconds 1
}
function Data-Page {
    Click '^(Settings|系统设置|系統設定)$'
    Click '^(Data management|数据管理|資料管理)$'
}
function Export-Verified([string]$FileName) {
    Top
    Click '^(Export backup|匯出備份|导出备份)'
    Save-Document $FileName
    for ($i=0; $i -lt 12; $i++) {
        $tree = Ui
        if ($tree.OuterXml -match '(Backup saved|備份成功|备份成功)') { break }
        Check ($tree.OuterXml -notmatch '(Operation not completed|操作未完成)') 'Actual file export failed.'
    }
    Check ($tree.OuterXml -match '(Backup saved|備份成功|备份成功)') 'Actual file export failed.'
    Check ($tree.OuterXml -match [regex]::Escape($FileName)) 'Provider changed the requested QA filename.'
    Adb @('pull',"/sdcard/Download/$FileName",(Join-Path $evidence $FileName)) | Out-Null
    Click '^(Done|完成)$'
}
function Import-Preview([string]$FileName) {
    Top
    Click '^(Import & restore|匯入還原|导入恢复)'
    Open-Document $FileName
    for ($i=0; $i -lt 12; $i++) {
        $tree = Ui
        if ($tree.OuterXml -match '(Restore preview|還原預覽|恢复预览)') { return }
        Check ($tree.OuterXml -notmatch '(Operation not completed|操作未完成)') 'Backup validation was rejected.'
    }
    throw 'Validated overwrite preview missing.'
}
function Confirm-Restore {
    Click '^(Replace and restore|確認覆蓋還原|确认覆盖恢复)$'
    Wait-Restore
}
function Wait-Restore {
    for ($i=0; $i -lt 12; $i++) {
        $tree = Ui
        if ($tree.OuterXml -match '(Restore complete|還原完成|恢复完成)') {
            Click '^(Done|完成)$'
            return
        }
        if ($tree.OuterXml -match '(Operation not completed|操作未完成)') { throw 'Restore error dialog appeared.' }
    }
    throw 'No completed restore was observed.'
}
