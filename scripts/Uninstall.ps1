$ErrorActionPreference='Stop'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
if(!([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run this uninstaller from an administrator PowerShell terminal.'}
$statePath=Join-Path (Split-Path -Parent $PSScriptRoot) '.local/install-state.json'
if(!(Test-Path -LiteralPath $statePath)){throw 'No installation state exists. Use the uninstaller belonging to the installed package.'}
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$inf=$state.PublishedInf
if($inf -notmatch '^oem\d+\.inf$'){throw 'Installation did not record a removable driver package.'}
$storedInf=Join-Path $env:SystemRoot "INF/$inf"
if((Get-FileHash -LiteralPath $storedInf).Hash -ne $state.PackageHash){throw 'Published INF changed since installation; nothing was removed.'}
& pnputil.exe /delete-driver $inf /uninstall
if($LASTEXITCODE -notin @(0,3010)){throw 'Driver package removal failed; state retained.'}
foreach($device in $state.Devices){
    $key='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$device.InstanceId
    $filters=@((Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).LowerFilters | Where-Object {$_})
    $remaining=@($filters | Where-Object {$_ -ne 'AppleKeyboardFilter' -and $_ -ne 'vhf'})
    $remaining=@(@($device.PreviousLowerFilters)+$remaining | Where-Object {$_} | Select-Object -Unique)
    if($remaining.Count){Set-ItemProperty -LiteralPath $key -Name LowerFilters -Value $remaining}
    else {Remove-ItemProperty -LiteralPath $key -Name LowerFilters -ErrorAction SilentlyContinue}
    & pnputil.exe /restart-device $device.InstanceId
    if($LASTEXITCODE -notin @(0,3010)){Write-Warning 'Device restart requires a normal Windows restart.'}
}
Move-Item -LiteralPath $statePath -Destination "$statePath.uninstalled" -Force
Write-Output 'Removed the recorded package. Existing test-signing and certificate settings were not modified.'
