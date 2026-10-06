param([string]$VCToolsRoot,[string]$WindowsSdkRoot,[string]$WindowsSdkLibRoot,[string]$WdkRoot,[string]$SdkVersion='10.0.26100.0')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Toolchain.ps1')
$tc=Resolve-MagicKeyboardToolchain @PSBoundParameters
$root=Split-Path -Parent $PSScriptRoot
$src=Join-Path $root 'src/AppleKeyboardFilter.Driver'
$obj=Join-Path $root 'build/obj'
$package=Join-Path $root 'build/driver'
New-Item -ItemType Directory -Path $obj,$package -Force | Out-Null
$flags=@('/nologo','/c','/O2','/GS','/kernel','/Zl','/Zi','/W4','/WX','/DNTDDI_VERSION=0x0A000008','/D_AMD64_','/DAMD64','/D_WIN32_WINNT=0x0A00',"/I$($tc.VC)/include","/I$($tc.WDK)/Include/$($tc.Version)/km","/I$($tc.SDK)/Include/$($tc.Version)/shared","/I$($tc.SDK)/Include/$($tc.Version)/ucrt","/Fo$obj/","/Fd$obj/compiler.pdb")
& $tc.Compiler @flags "$src/Driver.c" "$src/AppleKeyboardReport.c" "$src/NativeActions.c"
if($LASTEXITCODE -ne 0){throw 'Driver compilation failed.'}
& $tc.Linker /nologo /driver /subsystem:native /entry:GsDriverEntry /nodefaultlib /machine:x64 /dynamicbase /nxcompat /integritycheck /debug "/pdb:$package/AppleKeyboardFilter.pdb" "/map:$package/AppleKeyboardFilter.map" "/out:$package/AppleKeyboardFilter.sys" "$obj/Driver.obj" "$obj/AppleKeyboardReport.obj" "$obj/NativeActions.obj" "/libpath:$($tc.WDK)/Lib/$($tc.Version)/km/x64" ntoskrnl.lib hal.lib wmilib.lib BufferOverflowFastFailK.lib vhfkm.lib
if($LASTEXITCODE -ne 0){throw 'Driver linking failed.'}
Copy-Item -LiteralPath "$src/AppleKeyboardFilter.inf" -Destination $package -Force
& $tc.Inf2Cat "/driver:$package" /os:10_X64 /uselocaltime
if($LASTEXITCODE -ne 0){throw 'Catalog generation failed.'}
Write-Output "Built unsigned x64 development package: $package. This is not a Microsoft-signed distribution."
