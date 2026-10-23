# Local persistent signing setup. Never prints a password or replaces a key.
param([switch]$CreateNew)
. "$PSScriptRoot\environment.ps1"
$signDir = Join-Path $projectRoot '.signing'
$key = Join-Path $signDir 'finance-release.p12'
$properties = Join-Path $signDir 'keystore.properties'
if ((Test-Path -LiteralPath $key) -and (Test-Path -LiteralPath $properties)) {
    Write-Output 'Existing local release signing configuration retained.'
    exit 0
}
if ((Test-Path -LiteralPath $key) -or (Test-Path -LiteralPath $properties)) {
    throw 'Partial signing setup found. Preserve it and recover the matching configuration; never generate a replacement key.'
}
if (-not $CreateNew) {
    throw 'Release key is missing. Restore the original .signing backup. Only the first-ever setup of an unpublished app may use -CreateNew.'
}
$published = Get-ChildItem (Join-Path $projectRoot 'artifacts\verification') -Filter '*apk-manifest.json' -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'release candidate' }
if ($published) {
    throw 'A release signing identity was already delivered. Restore its original key; do not generate a replacement.'
}
New-Item -ItemType Directory -Path $signDir -Force | Out-Null
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$acl = [Security.AccessControl.DirectorySecurity]::new()
$acl.SetOwner($sid)
$acl.SetAccessRuleProtection($true,$false)
foreach ($identity in @($sid,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'))) {
    $rule = [Security.AccessControl.FileSystemAccessRule]::new($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $acl.AddAccessRule($rule)
}
Set-Acl -LiteralPath $signDir -AclObject $acl
$env:FINANCE_SIGNING_SECRET = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant()
try {
    & "$env:JAVA_HOME\bin\keytool.exe" -genkeypair -noprompt -storetype PKCS12 `
        -keystore $key -alias finance-release -keyalg RSA -keysize 3072 -validity 10000 `
        -storepass:env FINANCE_SIGNING_SECRET -keypass:env FINANCE_SIGNING_SECRET `
        -dname 'CN=Finance Local Release,OU=Personal,O=Local,C=CN'
    if ($LASTEXITCODE -ne 0) { throw 'Release key creation did not complete; preserve any partial file.' }
    $lines = @('storeFile=.signing/finance-release.p12','keyAlias=finance-release',
        "storePassword=$env:FINANCE_SIGNING_SECRET","keyPassword=$env:FINANCE_SIGNING_SECRET")
    [IO.File]::WriteAllLines($properties,$lines,[Text.UTF8Encoding]::new($false))
    Write-Output 'Persistent local release key created in .signing; key and secret are excluded from Git. Back up this private folder separately.'
} finally {
    Remove-Item Env:\FINANCE_SIGNING_SECRET -ErrorAction SilentlyContinue
}
