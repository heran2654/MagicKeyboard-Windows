param([string]$PackagePath=(Join-Path (Split-Path -Parent $PSScriptRoot) 'build/driver'))
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$destination=Join-Path $root 'dist/submission'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
foreach($name in @('AppleKeyboardFilter.sys','AppleKeyboardFilter.inf','AppleKeyboardFilter.cat')){
    Copy-Item -LiteralPath (Join-Path $PackagePath $name) -Destination $destination -Force
}
$cab=Join-Path $root 'dist/MagicKeyboardWindows-submission.cab'
$ddf=Join-Path $root 'build/submission.ddf'
$lines=@('.OPTION EXPLICIT','.Set Cabinet=on','.Set Compress=on','.Set CompressionType=MSZIP','.Set CabinetNameTemplate=MagicKeyboardWindows-submission.cab',('.Set DiskDirectoryTemplate="'+(Join-Path $root 'dist')+'"'),'.Set DestinationDir=MagicKeyboardWindows')
foreach($name in @('AppleKeyboardFilter.sys','AppleKeyboardFilter.inf','AppleKeyboardFilter.cat')){$lines+='"'+(Join-Path $destination $name)+'"'}
$lines | Set-Content -LiteralPath $ddf -Encoding ascii
& makecab.exe /F $ddf
if($LASTEXITCODE -ne 0){throw 'Submission CAB generation failed.'}
Write-Output "Prepared CAB: $cab. The publisher must EV-sign and submit it; this script does not obtain Microsoft approval."
