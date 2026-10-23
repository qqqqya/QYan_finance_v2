. "$PSScriptRoot\environment.ps1"
$evidence = Join-Path $projectRoot 'artifacts\verification'
$paths = Get-Content (Join-Path $evidence 'stage4-native-paths.json') -Raw | ConvertFrom-Json
function Read-Backup([string]$Name) {
    # These files were exported by the actual Android app and pulled from Downloads.
    $doc = Get-Content (Join-Path $evidence $Name) -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    if ($doc.format -cne 'finance-backup' -or $doc.schemaVersion -ne 1 -or $doc.checksum.algorithm -cne 'SHA-256') { throw "Invalid header: $Name" }
    return $doc
}
function Same-Data($Left,$Right,[string]$Label) {
    $a = $Left.data | ConvertTo-Json -Depth 100 -Compress
    $b = $Right.data | ConvertTo-Json -Depth 100 -Compress
    if ($a -cne $b) { throw "Field mismatch: $Label" }
    Write-Output "PASS: $Label - all business fields, IDs, history, array order and settings equal."
}
$a = Read-Backup $paths.a
$b = Read-Backup $paths.b
Same-Data $a $b 'physical export A -> empty book -> restore twice -> physical export B'
Same-Data (Read-Backup 'stage4-all-types.moneybak') $a 'all-entity fixture -> actual SAF restore/export'
Same-Data (Read-Backup 'stage4-upgrade-export.moneybak') (Read-Backup $paths.recovered) 'private copy restores pre-import upgraded data'
$zero = Read-Backup $paths.zero
if ($zero.data.projects.Count -ne 9 -or $zero.data.bills.Count -ne 0 -or $zero.data.memos.Count -ne 0 -or $zero.data.projectEntries.Count -ne 0 -or $zero.data.editHistory.Count -ne 0) { throw 'Reset entity counts invalid.' }
if (@($zero.data.balanceRecords | Where-Object { $_.balanceMinor -ne 0 }).Count -ne 0) { throw 'Reset balances not zero.' }
if ($zero.data.settings.themeMode -cne 'system' -or $zero.data.settings.languageMode -cne 'system') { throw 'Reset settings not defaults.' }
Write-Output 'PASS: actual post-reset file contains 9 default projects, zero balances, no user records/history and default settings.'
if ($paths.PSObject.Properties.Name -contains 'afterKill') {
    Same-Data $b (Read-Backup $paths.afterKill) 'SQLite write-journal interruption -> restart -> physical export'
}
if ($paths.PSObject.Properties.Name -contains 'large') {
    Same-Data (Read-Backup 'stage4-large-fixture.moneybak') (Read-Backup $paths.large) '30.59 MB fixture -> actual Android restore -> physical export'
}
