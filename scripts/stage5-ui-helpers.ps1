. "$PSScriptRoot\stage4-ui-helpers.ps1"
$shots = Join-Path $projectRoot 'artifacts\screenshots\stage5'
New-Item -ItemType Directory -Path $shots -Force | Out-Null
function Ui([string]$Name = 'stage5-native-current') {
    Adb @('shell','uiautomator','dump','/sdcard/finance5-ui.xml') | Out-Null
    $path = Join-Path $evidence "$Name.xml"
    Adb @('pull','/sdcard/finance5-ui.xml',$path) | Out-Null
    return [xml](Get-Content -LiteralPath $path -Raw -Encoding utf8)
}
function Size-OfScreen($Tree) {
    $bounds = $Tree.SelectSingleNode('//node').GetAttribute('bounds')
    $m = [regex]::Match($bounds,'\[\d+,\d+\]\[(\d+),(\d+)\]')
    return @([int]$m.Groups[1].Value,[int]$m.Groups[2].Value)
}
function Top {
    $size = Size-OfScreen (Ui)
    for($i=0;$i -lt 4;$i++){
        Adb @('shell','input','swipe',"$($size[0]-30)","$([int]($size[1]*.28))",
            "$($size[0]-30)","$([int]($size[1]*.85))",'100') | Out-Null
    }
}
function Seek([string]$Pattern,[switch]$Field) {
    for($i=0;$i -lt 15;$i++){
        $tree = Ui
        $nodes = @($tree.SelectNodes('//node') | Where-Object {
            $_.GetAttribute('package') -eq $package -and
            $(if($Field){$_.GetAttribute('class') -eq 'android.widget.EditText' -and $_.GetAttribute('hint') -match $Pattern}
              else{$_.GetAttribute('clickable') -eq 'true' -and $_.GetAttribute('content-desc') -match $Pattern})
        })
        if($nodes.Count){return $nodes[0]}
        $size = Size-OfScreen $tree
        Adb @('shell','input','swipe',"$($size[0]-30)","$([int]($size[1]*.85))",
            "$($size[0]-30)","$([int]($size[1]*.28))",'150') | Out-Null
    }
    throw "QA control missing: $Pattern"
}
