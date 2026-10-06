#define APPLE_REPORT_UNIT_TEST
#include "../src/AppleKeyboardFilter.Driver/AppleKeyboardReport.c"
#include <assert.h>
#include <string.h>
#include <stdio.h>
ULONG g_EmitFnAsMenu = 1;
int main(void) {
    UCHAR p[11] = {0xa1,1,0,0,0,0,0,0,0,0,2};
    assert(TryProcessAppleKeyboardTransportBuffer(p,11,2));
    assert(p[4]==0x65 && p[10]==0);
    UCHAR released[11]={0xa1,1,0,0,0,0,0,0,0,0,0};
    TryProcessAppleKeyboardTransportBuffer(released,11,2);
    assert(released[4]==0);
    UCHAR combo[11]={0xa1,1,0x02,0,0x44,0,0,0,0,0,3};
    TryProcessAppleKeyboardTransportBuffer(combo,11,2);
    assert(combo[2]==2 && combo[4]==0x44 && combo[5]==0x65 && combo[10]==1);
    UCHAR duplicate[11]={0xa1,1,0,0,0x65,0,0,0,0,0,2};
    TryProcessAppleKeyboardTransportBuffer(duplicate,11,2);
    assert(duplicate[4]==0x65 && duplicate[5]==0);
    UCHAR full[11]={0xa1,1,0,0,4,5,6,7,8,9,2};
    TryProcessAppleKeyboardTransportBuffer(full,11,2);
    for(int i=4;i<10;i++) assert(full[i]==i);
    UCHAR wrong[11]={0xa1,3,0,0,0,0,0,0,0,0,2}, original[11];
    memcpy(original,wrong,11);
    assert(!TryProcessAppleKeyboardTransportBuffer(wrong,11,2));
    assert(!memcmp(original,wrong,11));
    assert(!TryProcessAppleKeyboardTransportBuffer(wrong,10,2));
    assert(!TryProcessAppleKeyboardTransportBuffer(wrong,11,0));
    assert(!TryProcessAppleKeyboardTransportBuffer(NULL,11,2));
    UCHAR outbound[11]={0xa2,1,0,0,0,0,0,0,0,0,2};
    assert(!TryProcessAppleKeyboardTransportBuffer(outbound,11,2));
    UCHAR reserved[11]={0xa1,1,0,4,0,0,0,0,0,0,2};
    TryProcessAppleKeyboardTransportBuffer(reserved,11,2); assert(reserved[4]==0);
    UCHAR unknown[11]={0xa1,1,0,0,0,0,0,0,0,0,0x82};
    TryProcessAppleKeyboardTransportBuffer(unknown,11,2); assert(unknown[4]==0);
    UCHAR disabled[11]={0xa1,1,0,0,0,0,0,0,0,0,2};
    g_EmitFnAsMenu=0; TryProcessAppleKeyboardTransportBuffer(disabled,11,2);
    assert(disabled[4]==0 && disabled[10]==2);
    puts("PASS: Fn press/release, modifier preservation, duplicate, rollover, invalid reports, disabled mode");
    return 0;
}
