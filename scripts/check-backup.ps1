$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$schemaPath = Join-Path $projectRoot 'docs\backup\finance-backup-v1.schema.json'
$sample = Get-Content -LiteralPath (Join-Path $projectRoot 'docs\backup\finance-backup-v1.minimal.json') -Raw -Encoding utf8
if (!(Test-Json -Json $sample -SchemaFile $schemaPath)) {
    throw 'The minimal backup example does not match its schema.'
}
$invalid = $sample | ConvertFrom-Json
$invalid.data.balanceRecords[0].balanceMinor = 0.01
if (Test-Json -Json ($invalid | ConvertTo-Json -Depth 30) -SchemaFile $schemaPath -ErrorAction SilentlyContinue) {
    throw 'Fractional minor-unit amounts must be rejected.'
}
'Backup schema checks passed (valid sample / rejected fractional minor units).'
