param([Parameter(Mandatory)][string]$PackagePath,[string]$SignToolPath)
$ErrorActionPreference='Stop'
if(!$SignToolPath){
    $kits=Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/bin'
    $SignToolPath=Get-ChildItem -LiteralPath $kits -Directory | Sort-Object Name -Descending | ForEach-Object {Join-Path $_.FullName 'x64/signtool.exe'} | Where-Object {Test-Path -LiteralPath $_} | Select-Object -First 1
}
if(!$SignToolPath -or !(Test-Path -LiteralPath $SignToolPath)){throw 'Install Windows SDK signing tools or pass -SignToolPath.'}
foreach($name in @('AppleKeyboardFilter.sys','AppleKeyboardFilter.cat')){
    $path=Join-Path $PackagePath $name
    $signature=Get-AuthenticodeSignature -LiteralPath $path
    if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'CN=Microsoft Windows Hardware Compatibility Publisher(?:,|$)'){
        throw "$name is not a valid Microsoft hardware-dashboard signed file. A local test certificate is insufficient."
    }
    & $SignToolPath verify /kp /v $path
    if($LASTEXITCODE -ne 0){throw "Kernel-policy signature verification failed: $name"}
}
foreach($name in @('AppleKeyboardFilter.inf','AppleKeyboardFilter.sys')){
    & $SignToolPath verify /kp /c (Join-Path $PackagePath 'AppleKeyboardFilter.cat') (Join-Path $PackagePath $name)
    if($LASTEXITCODE -ne 0){throw "$name does not match the signed catalog."}
}
Write-Output 'Microsoft signatures, kernel policy and INF catalog membership verified.'
