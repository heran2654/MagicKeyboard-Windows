param([Parameter(Mandatory)][string]$PackagePath,[string]$SignToolPath)
$ErrorActionPreference='Stop'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
if(!([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run this installer from an administrator PowerShell terminal.'}
# The public installer never enables test-signing, changes Secure Boot, or imports a certificate.
& (Join-Path $PSScriptRoot 'Verify-SignedPackage.ps1') -PackagePath $PackagePath -SignToolPath $SignToolPath
$targets=@(Get-PnpDevice -PresentOnly | Where-Object InstanceId -match '^BTHENUM\\\{00001124-0000-1000-8000-00805F9B34FB\}_VID&0001004C_PID&0320')
if(!$targets.Count){throw 'No supported Bluetooth Magic Keyboard PID 0320 is connected.'}
$service=Get-CimInstance Win32_SystemDriver -Filter "Name='AppleKeyboardFilter'"
if($service){throw 'An existing AppleKeyboardFilter installation is present. Uninstall it using its original installer before installing this package.'}
$root=Split-Path -Parent $PSScriptRoot
$local=Join-Path $root '.local'
New-Item -ItemType Directory -Path $local -Force | Out-Null
$state=@{Devices=@();PackageHash=(Get-FileHash (Join-Path $PackagePath 'AppleKeyboardFilter.inf')).Hash;InstalledAt=[DateTimeOffset]::Now.ToString('o');PublishedInf=$null}
foreach($target in $targets){
    $key='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$target.InstanceId
    $filters=@((Get-ItemProperty -LiteralPath $key -ErrorAction Stop).LowerFilters | Where-Object {$_})
    if($filters.Count){throw 'This device already has lower filters. Their ordering requires review; no driver was installed.'}
    $state.Devices+=@{InstanceId=$target.InstanceId;PreviousLowerFilters=$filters}
}
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $local 'install-state.json') -Encoding utf8
& pnputil.exe /add-driver (Join-Path $PackagePath 'AppleKeyboardFilter.inf') /install
if($LASTEXITCODE -notin @(0,3010)){throw 'Driver installation failed. State backup is retained in .local.'}
foreach($target in $targets){
    $inf=(Get-PnpDeviceProperty -InstanceId $target.InstanceId -KeyName DEVPKEY_Device_DriverInfPath).Data
    if($inf -notmatch '^oem\d+\.inf$'){throw 'Cannot identify the newly installed package.'}
    $state.PublishedInf=$inf
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $local 'install-state.json') -Encoding utf8
    & pnputil.exe /restart-device $target.InstanceId
    if($LASTEXITCODE -notin @(0,3010)){throw 'Device restart failed. Restart Windows and run Check-Driver.ps1.'}
}
& (Join-Path $PSScriptRoot 'Check-Driver.ps1') -RequireReady -RequireMicrosoftSigner
Write-Output 'Installed. Fn+Esc toggles Fn inversion; the lock key sends Windows+L. Verify physical keys. No Windows restart was initiated.'
