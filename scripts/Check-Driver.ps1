param([switch]$All,[switch]$Json,[switch]$RequireReady,[switch]$RequireMicrosoftSigner)
$ErrorActionPreference='Stop'
function Property($id,$name){try{(Get-PnpDeviceProperty -InstanceId $id -KeyName $name -ErrorAction Stop).Data}catch{$null}}
$devices=if($All){Get-PnpDevice}else{Get-PnpDevice -PresentOnly}
$targets=@($devices | Where-Object InstanceId -match '^BTHENUM\\\{00001124-0000-1000-8000-00805F9B34FB\}_VID&0001004C_PID&0320')
$details=@(foreach($device in $targets){
    $key='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$device.InstanceId
    $filters=@((Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).LowerFilters | Where-Object {$_})
    [pscustomobject]@{Status=$device.Status;Class=$device.Class;InstanceId=$device.InstanceId;DriverInfPath=(Property $device.InstanceId 'DEVPKEY_Device_DriverInfPath');DriverVersion=(Property $device.InstanceId 'DEVPKEY_Device_DriverVersion');LowerFilters=$filters;FilterBound=($filters -contains 'AppleKeyboardFilter' -and $filters -contains 'vhf')}
})
$virtual=@(Get-PnpDevice -PresentOnly -Class Keyboard,HIDClass | Where-Object InstanceId -match '^(HID\\HID_DEVICE_SYSTEM_VHF|VHF\\)' | Where-Object {
    $ids=Property $_.InstanceId 'DEVPKEY_Device_HardwareIds'
    ($ids -join ' ') -match 'VID_05AC&PID_F320'
} | Select-Object Status,Class,InstanceId)
$service=Get-CimInstance Win32_SystemDriver -Filter "Name='AppleKeyboardFilter'"
$settings=Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\AppleKeyboardFilter' -ErrorAction SilentlyContinue
$signature=if($service -and $service.PathName){
    $path=$service.PathName.Replace('\SystemRoot',$env:SystemRoot).Trim('"')
    Get-AuthenticodeSignature -LiteralPath $path -ErrorAction SilentlyContinue
}
$microsoftSigned=$signature -and $signature.Status -eq 'Valid' -and $signature.SignerCertificate.Subject -match 'CN=Microsoft Windows Hardware Compatibility Publisher(?:,|$)'
$ready=$targets.Count -gt 0 -and ($details | Where-Object FilterBound).Count -gt 0 -and $service.State -eq 'Running' -and $null -ne $settings.NativeVhfStatus -and $settings.NativeVhfStatus -eq 0 -and ($virtual | Where-Object {$_.Class -eq 'Keyboard' -and $_.Status -eq 'OK'}).Count -gt 0 -and ($virtual | Where-Object {$_.Class -eq 'HIDClass' -and $_.Status -eq 'OK'}).Count -gt 0
if($RequireMicrosoftSigner){$ready=$ready -and $microsoftSigned}
$result=[pscustomobject]@{Ready=[bool]$ready;DriverState=$service.State;NativeVhfStatus=$settings.NativeVhfStatus;InvertFn=$settings.InvertFn;MicrosoftSigned=[bool]$microsoftSigned;Targets=$details;VirtualDevices=$virtual;Note='Ready checks enumeration and binding; physical keys and reconnect behavior require testing.'}
if($Json){$result | ConvertTo-Json -Depth 6}else{$result | Format-List}
if($RequireReady -and !$ready){exit 2}
