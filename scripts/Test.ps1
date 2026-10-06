param([string]$VCToolsRoot,[string]$WindowsSdkRoot,[string]$WindowsSdkLibRoot,[string]$WdkRoot,[string]$SdkVersion='10.0.26100.0')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Toolchain.ps1')
$tc=Resolve-MagicKeyboardToolchain @PSBoundParameters
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'build/tests'
New-Item -ItemType Directory -Path $out -Force | Out-Null
foreach($name in @('test-actions','test-reports')){
    & $tc.Compiler /nologo /MT /W4 /WX "/I$($tc.VC)/include" "/I$($tc.SDK)/Include/$($tc.Version)/ucrt" "$root/tests/$name.c" "/Fo$out/$name.obj" "/Fe$out/$name.exe" /link /nodefaultlib:oldnames.lib "/libpath:$($tc.VC)/lib/x64" "/libpath:$($tc.SdkLib)/ucrt/x64" "/libpath:$($tc.SdkLib)/um/x64"
    if($LASTEXITCODE -ne 0){throw "Compilation failed: $name"}
    & "$out/$name.exe"
    if($LASTEXITCODE -ne 0){throw "Test failed: $name"}
}
& (Join-Path $root 'tests/Test-Lifecycle.ps1') -Toolchain $tc
if($LASTEXITCODE -ne 0){throw 'Lifecycle test failed.'}
