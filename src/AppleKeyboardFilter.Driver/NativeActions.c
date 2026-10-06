#include "Driver.h"

static UCHAR Descriptor[]={
    // Virtual keyboard is used only for Fn tap (Win+Space) and lock (Win+L).
    0x05,1,0x09,6,0xa1,1,0x85,1,
    0x05,7,0x19,0xe0,0x29,0xe7,0x15,0,0x25,1,0x75,1,0x95,8,0x81,2,
    0x95,1,0x75,8,0x81,3,
    0x19,0,0x29,0x65,0x15,0,0x25,0x65,0x75,8,0x95,6,0x81,0,0xc0,
    // Standard consumer brightness and media usages, one bit each.
    0x05,0x0c,0x09,1,0xa1,1,0x85,2,
    0x15,0,0x25,1,0x75,1,0x95,8,
    0x09,0x70,0x09,0x6f,0x09,0xb6,0x09,0xcd,
    0x09,0xb5,0x09,0xe2,0x09,0xea,0x09,0xe9,0x81,2,0xc0
};

static VOID SaveInversion(PDEVICE_OBJECT DeviceObject,PVOID Context) {
    UNREFERENCED_PARAMETER(DeviceObject);
    PDEVICE_EXTENSION extension=(PDEVICE_EXTENSION)Context;
    for(;;){
        KIRQL irql;KeAcquireSpinLock(&extension->ReportLock,&irql);
        ULONG value=extension->Actions.Inverted;
        KeReleaseSpinLock(&extension->ReportLock,irql);
        OBJECT_ATTRIBUTES attributes;HANDLE key=NULL;UNICODE_STRING name;
        InitializeObjectAttributes(&attributes,&g_ServiceRegistryPath,OBJ_CASE_INSENSITIVE|OBJ_KERNEL_HANDLE,NULL,NULL);
        if(NT_SUCCESS(ZwOpenKey(&key,KEY_SET_VALUE,&attributes))){
            RtlInitUnicodeString(&name,L"InvertFn");ZwSetValueKey(key,&name,0,REG_DWORD,&value,sizeof(value));ZwClose(key);
        }
        KeAcquireSpinLock(&extension->ReportLock,&irql);
        BOOLEAN repeat=extension->Actions.Inverted!=value;
        if(!repeat)extension->SaveQueued=0;
        KeReleaseSpinLock(&extension->ReportLock,irql);
        if(!repeat)break;
    }
    IoReleaseRemoveLock(&extension->RemoveLock,extension->SaveWorkItem);
}

NTSTATUS InitializeNativeActions(PDEVICE_EXTENSION Extension) {
    PAGED_CODE();
    KeInitializeSpinLock(&Extension->ReportLock);
    ULONG inverted=0;ReadDriverDword(&g_ServiceRegistryPath,L"InvertFn",&inverted);
    Extension->Actions.Inverted=(UCHAR)(inverted!=0);
    Extension->SaveWorkItem=IoAllocateWorkItem(Extension->DeviceObject);
    VHF_CONFIG config;VHF_CONFIG_INIT(&config,Extension->DeviceObject,sizeof(Descriptor),Descriptor);
    config.VendorID=0x05ac;config.ProductID=0xf320;config.VersionNumber=3;
    NTSTATUS status=VhfCreate(&config,&Extension->VhfHandle);
    if(NT_SUCCESS(status)){
        status=VhfStart(Extension->VhfHandle);
        if(!NT_SUCCESS(status)){VhfDelete(Extension->VhfHandle,TRUE);Extension->VhfHandle=NULL;}
    }
    OBJECT_ATTRIBUTES attributes;HANDLE key=NULL;UNICODE_STRING name;
    InitializeObjectAttributes(&attributes,&g_ServiceRegistryPath,OBJ_CASE_INSENSITIVE|OBJ_KERNEL_HANDLE,NULL,NULL);
    if(NT_SUCCESS(ZwOpenKey(&key,KEY_SET_VALUE,&attributes))){
        ULONG recorded=(ULONG)status;RtlInitUnicodeString(&name,L"NativeVhfStatus");
        ZwSetValueKey(key,&name,0,REG_DWORD,&recorded,sizeof(recorded));ZwClose(key);
    }
    return status;
}
VOID StopNativeActions(PDEVICE_EXTENSION Extension) {
    PAGED_CODE();
    // Drain submissions before destroying the handle. Keep the lower VHF device
    // alive until VhfDelete completes; never forward REMOVE_DEVICE first.
    KIRQL irql;KeAcquireSpinLock(&Extension->ReportLock,&irql);
    Extension->NativeStopping=TRUE;
    VHFHANDLE handle=Extension->VhfHandle;
    Extension->VhfHandle=NULL;
    KeReleaseSpinLock(&Extension->ReportLock,irql);
    if(handle)VhfDelete(handle,TRUE);
}
VOID CleanupNativeActions(PDEVICE_EXTENSION Extension) {
    PAGED_CODE();
    // Called only after IoReleaseRemoveLockAndWait, including queued registry work.
    if(Extension->SaveWorkItem){IoFreeWorkItem(Extension->SaveWorkItem);Extension->SaveWorkItem=NULL;}
}
static VOID SubmitShortcut(PDEVICE_EXTENSION Extension,UCHAR Key) {
    UCHAR report[9]={1,8,0,Key,0,0,0,0,0};
    HID_XFER_PACKET packet={report,sizeof(report),1};
    if(NT_SUCCESS(VhfReadReportSubmit(Extension->VhfHandle,&packet))){
        RtlZeroMemory(&report[1],8);VhfReadReportSubmit(Extension->VhfHandle,&packet);
    }
}
BOOLEAN ProcessNativeTransport(PDEVICE_EXTENSION Extension,PUCHAR Buffer,ULONG Size,ULONG PrefixBytes) {
    if(!Buffer||PrefixBytes<1||PrefixBytes>2||Size!=PrefixBytes+9)return FALSE;
    if((PrefixBytes==2&&(Buffer[0]!=0xa1||Buffer[1]!=1))||(PrefixBytes==1&&Buffer[0]!=1))return FALSE;
    PUCHAR report=Buffer+PrefixBytes;
    if((report[1]&~1)||(report[8]&~0x0b))return FALSE;
    KIRQL irql;KeAcquireSpinLock(&Extension->ReportLock,&irql);
    if(Extension->NativeStopping){KeReleaseSpinLock(&Extension->ReportLock,irql);return TRUE;}
    if(!Extension->VhfHandle){KeReleaseSpinLock(&Extension->ReportLock,irql);return FALSE;}
    ACTION_RESULT result=ProcessActionReport(&Extension->Actions,report);
    if(result.ConsumerBits!=Extension->LastConsumerBits){
        UCHAR consumer[2]={2,result.ConsumerBits};HID_XFER_PACKET packet={consumer,sizeof(consumer),2};
        if(NT_SUCCESS(VhfReadReportSubmit(Extension->VhfHandle,&packet)))Extension->LastConsumerBits=result.ConsumerBits;
    }
    if(result.FnTap)SubmitShortcut(Extension,0x2c);
    if(result.LockTap)SubmitShortcut(Extension,0x0f);
    BOOLEAN queue=result.InversionChanged&&Extension->SaveWorkItem&&Extension->SaveQueued==0;
    if(queue)Extension->SaveQueued=1;
    KeReleaseSpinLock(&Extension->ReportLock,irql);
    if(queue){
        if(NT_SUCCESS(IoAcquireRemoveLock(&Extension->RemoveLock,Extension->SaveWorkItem)))
            IoQueueWorkItem(Extension->SaveWorkItem,SaveInversion,DelayedWorkQueue,Extension);
        else InterlockedExchange(&Extension->SaveQueued,0);
    }
    return TRUE;
}
