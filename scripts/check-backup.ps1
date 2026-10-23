$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
foreach ($version in @(1, 2)) {
    $schemaPath = Join-Path $projectRoot "docs\backup\finance-backup-v$version.schema.json"
    $sample = Get-Content -LiteralPath (Join-Path $projectRoot "docs\backup\finance-backup-v$version.minimal.json") -Raw -Encoding utf8
    if (!(Test-Json -Json $sample -SchemaFile $schemaPath)) { throw "Invalid v$version minimal example." }
    $invalid = $sample | ConvertFrom-Json
    $invalid.data.balanceRecords[0].balanceMinor = 0.01
    if (Test-Json -Json ($invalid | ConvertTo-Json -Depth 30) -SchemaFile $schemaPath -ErrorAction SilentlyContinue) { throw 'Fractional minor-unit amounts must be rejected.' }
}
'Backup v1/v2 schema checks passed (valid samples / rejected fractional minor units).'
