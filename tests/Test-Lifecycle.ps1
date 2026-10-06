param([string]$SourceRoot='', [switch]$ExpectFailure, $Toolchain)
$ErrorActionPreference='Stop'
function Extract-Function([string]$text,[string]$name) {
    $match=[regex]::Match($text,'(?m)^(?:NTSTATUS|VOID|BOOLEAN) '+[regex]::Escape($name)+'\(')
    if(!$match.Success){return ''}
    $start=$text.IndexOf('{',$match.Index); $depth=1;$end=$start+1
    while($depth -gt 0 -and $end -lt $text.Length){if($text[$end] -eq '{'){$depth++};if($text[$end] -eq '}'){$depth--};$end++}
    return $text.Substring($match.Index,$end-$match.Index)
}
$root=Join-Path (Split-Path -Parent $PSScriptRoot) 'src/AppleKeyboardFilter.Driver'
if($SourceRoot){$root=$SourceRoot}
$native=Get-Content -LiteralPath "$root/NativeActions.c" -Raw
$driver=Get-Content -LiteralPath "$root/Driver.c" -Raw
$functions=(Extract-Function $native 'StopNativeActions')+"`n"+(Extract-Function $native 'CleanupNativeActions')+"`n"+(Extract-Function $driver 'DispatchPnp')
$prefix=@'
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#undef assert
#define assert(c) do {if(!(c)){fprintf(stderr,"REGRESSION: %s at line %d\n",#c,__LINE__);exit(99);}} while(0)
#define PAGED_CODE() ((void)0)
#define TRUE 1
#define FALSE 0
#define NT_SUCCESS(s) ((s)>=0)
#define IRP_MN_REMOVE_DEVICE 2
#define IRP_MN_SURPRISE_REMOVAL 23
#define IRP_MN_DEVICE_USAGE_NOTIFICATION 22
#define IRP_MN_START_DEVICE 0
#define DO_POWER_PAGABLE 0x2000
#define STATUS_SUCCESS 0
typedef void VOID;typedef int NTSTATUS;typedef int KIRQL;typedef void* VHFHANDLE;
typedef struct _EXT {int ReportLock,NativeStopping,RemoveLock;VHFHANDLE VhfHandle;void* SaveWorkItem;void* LowerDeviceObject;} EXT,*PDEVICE_EXTENSION;
typedef struct _DEV {EXT* DeviceExtension;struct _DEV* AttachedDevice;int Flags;} DEV,*PDEVICE_OBJECT;
typedef struct _STACK {int MinorFunction;} STACK,*PIO_STACK_LOCATION;
typedef struct _IRP {STACK stack;} IRP,*PIRP;
static int alive=1,drained=0,deletes=0,frees=0,locked=0;
static void KeAcquireSpinLock(int* l,KIRQL* i){(void)l;*i=0;assert(!locked);locked=1;}
static void KeReleaseSpinLock(int* l,KIRQL i){(void)l;(void)i;assert(locked);locked=0;}
static void VhfDelete(VHFHANDLE h,int wait){assert(alive);assert(!locked);assert(h);assert(wait);deletes++;}
static void IoFreeWorkItem(void* item){assert(drained);assert(item);frees++;}
static NTSTATUS IoAcquireRemoveLock(int* l,PIRP i){(void)l;(void)i;return 0;}
static STACK* IoGetCurrentIrpStackLocation(PIRP i){return &i->stack;}
static NTSTATUS CompleteRequest(PIRP i,NTSTATUS s,int n){(void)i;(void)n;return s;}
static void IoSkipCurrentIrpStackLocation(PIRP i){(void)i;}
static NTSTATUS IoCallDriver(void* lower,PIRP i){(void)lower;if(i->stack.MinorFunction==IRP_MN_REMOVE_DEVICE)alive=0;return 0;}
static void IoReleaseRemoveLockAndWait(int* l,PIRP i){(void)l;(void)i;drained=1;}
static void IoReleaseRemoveLock(int* l,PIRP i){(void)l;(void)i;}
static void IoCopyCurrentIrpStackLocationToNext(PIRP i){(void)i;}
static void UsageNotificationComplete(void){}
static void StartDeviceComplete(void){}
static void IoSetCompletionRoutine(PIRP i,void(*r)(void),void* e,int a,int b,int c){(void)i;(void)r;(void)e;(void)a;(void)b;(void)c;}
static void CleanupNativeActions(PDEVICE_EXTENSION e);
static void RemoveDevice(PDEVICE_OBJECT d){CleanupNativeActions(d->DeviceExtension);}
'@
$suffix=@'
int main(void){
 EXT ext={0};DEV dev={&ext,0,0};IRP irp={{IRP_MN_REMOVE_DEVICE}};
 ext.VhfHandle=(void*)1;ext.SaveWorkItem=(void*)2;ext.LowerDeviceObject=(void*)3;
 assert(DispatchPnp(&dev,&irp)==0);
 assert(ext.NativeStopping&&ext.VhfHandle==NULL&&ext.SaveWorkItem==NULL);
 assert(deletes==1&&frees==1&&drained&&!alive);
 memset(&ext,0,sizeof(ext));alive=1;drained=0;deletes=0;frees=0;
 ext.VhfHandle=(void*)1;ext.SaveWorkItem=(void*)2;ext.LowerDeviceObject=(void*)3;
 irp.stack.MinorFunction=IRP_MN_SURPRISE_REMOVAL;
 assert(DispatchPnp(&dev,&irp)==0);assert(deletes==1&&ext.NativeStopping&&ext.SaveWorkItem);
 irp.stack.MinorFunction=IRP_MN_REMOVE_DEVICE;
 assert(DispatchPnp(&dev,&irp)==0);assert(deletes==1&&frees==1);
 puts("PASS: production PnP removal cleans VHF before lower destruction; surprise removal is idempotent; registry work freed after drain");
 return 0;
}
'@
($prefix+"`n"+$functions+"`n"+$suffix) | Set-Content -LiteralPath "$PSScriptRoot/../build/tests/test-lifecycle.c" -Encoding utf8
& $Toolchain.Compiler /nologo /MT /W4 /WX "/I$($Toolchain.VC)/include" "/I$($Toolchain.SDK)/Include/$($Toolchain.Version)/ucrt" "$PSScriptRoot/../build/tests/test-lifecycle.c" "/Fo$PSScriptRoot/../build/tests/test-lifecycle.obj" "/Fe$PSScriptRoot/../build/tests/test-lifecycle.exe" /link /nodefaultlib:oldnames.lib "/libpath:$($Toolchain.VC)/lib/x64" "/libpath:$($Toolchain.SdkLib)/ucrt/x64" "/libpath:$($Toolchain.SdkLib)/um/x64"
if($LASTEXITCODE -ne 0){throw 'Lifecycle harness compilation failed'}
& "$PSScriptRoot/../build/tests/test-lifecycle.exe"
if($ExpectFailure){if($LASTEXITCODE -eq 0){throw 'Expected old-driver regression was not reproduced'};Write-Output 'PASS: crashed production source reproduces use of VHF after lower device destruction'}
elseif($LASTEXITCODE -ne 0){throw 'Lifecycle regression failed'}
