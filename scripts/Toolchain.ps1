function Resolve-MagicKeyboardToolchain {
    param([string]$VCToolsRoot,[string]$WindowsSdkRoot,[string]$WindowsSdkLibRoot,[string]$WdkRoot,[string]$SdkVersion='10.0.26100.0')
    if(!$VCToolsRoot){
        $vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
        if(!(Test-Path -LiteralPath $vswhere)){throw 'Pass -VCToolsRoot, or install Visual Studio C++ tools.'}
        $vs=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if(!$vs){throw 'Visual Studio C++ tools not found.'}
        $version=(Get-Content -LiteralPath (Join-Path $vs 'VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt') -Raw).Trim()
        $VCToolsRoot=Join-Path $vs "VC/Tools/MSVC/$version"
    }
    if(!$WindowsSdkRoot){$WindowsSdkRoot=Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10'}
    if(!$WdkRoot){$WdkRoot=$WindowsSdkRoot}
    $sdkLib=Join-Path $WindowsSdkRoot "Lib/$SdkVersion"
    if(!(Test-Path -LiteralPath $sdkLib)){$sdkLib=Join-Path $WindowsSdkRoot 'Lib';if(!(Test-Path -LiteralPath $sdkLib)){$sdkLib=$WindowsSdkRoot}}
    if($WindowsSdkLibRoot){$sdkLib=$WindowsSdkLibRoot}
    $kitCompiler=Join-Path $VCToolsRoot 'bin/Hostx64/x64/cl.exe'
    if(!(Test-Path -LiteralPath $kitCompiler)){throw 'x64 C++ compiler not found.'}
    [pscustomobject]@{
        VC=$VCToolsRoot;SDK=$WindowsSdkRoot;WDK=$WdkRoot;Version=$SdkVersion
        Compiler=$kitCompiler;Linker=(Join-Path $VCToolsRoot 'bin/Hostx64/x64/link.exe');SdkLib=$sdkLib
        Inf2Cat=(Join-Path $WdkRoot "bin/$SdkVersion/x86/Inf2Cat.exe")
        SignTool=(Join-Path $WindowsSdkRoot "bin/$SdkVersion/x64/signtool.exe")
    }
}
