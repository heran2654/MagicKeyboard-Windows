#pragma once
// Portable report-to-action logic. No operating-system calls or allocations.
typedef struct _ACTION_STATE {
    unsigned char Actions[256];
    unsigned char Inverted, FnDown, FnUsed, LockDown;
} ACTION_STATE;
typedef struct _ACTION_RESULT {
    unsigned char ConsumerBits, FnTap, LockTap, InversionChanged;
} ACTION_RESULT;
static ACTION_RESULT ProcessActionReport(ACTION_STATE* state, unsigned char* report) {
    ACTION_RESULT result={0};
    unsigned char pressed[256]={0};
    unsigned char fn=(report[8]&2)!=0,lock=(report[8]&8)!=0;
    if(fn&&!state->FnDown)state->FnUsed=0;
    result.LockTap=(unsigned char)(lock&&!state->LockDown);
    for(unsigned i=0;i<6;i++){
        unsigned char key=report[2+i];pressed[key]=1;
        if(!key)continue;
        if(fn)state->FnUsed=1;
        if(!state->Actions[key]){
            if(fn&&key==0x29){state->Inverted^=1;result.InversionChanged=1;state->Actions[key]=4;}
            else if(key>=0x3a&&key<=0x45)state->Actions[key]=(state->Inverted!=fn)?2:1;
            else state->Actions[key]=fn?3:1;
        }
        unsigned char action=state->Actions[key];
        if(action==4){report[2+i]=0;continue;}
        if(action==2){
            if(key==0x3a)result.ConsumerBits|=1;
            else if(key==0x3b)result.ConsumerBits|=2;
            else if(key>=0x40)result.ConsumerBits|=(unsigned char)(4u<<(key-0x40));
            else {
                report[0]|=8;
                report[2+i]=key==0x3c?0x2b:key==0x3d?0x16:key==0x3e?0x0b:0x11;
                continue;
            }
            report[2+i]=0;
        } else if(action==3) {
            switch(key){
                case 0x2a:report[2+i]=0x4c;break;
                case 0x28:report[2+i]=0x49;break;
                case 0x50:report[2+i]=0x4a;break;
                case 0x4f:report[2+i]=0x4d;break;
                case 0x52:report[2+i]=0x4b;break;
                case 0x51:report[2+i]=0x4e;break;
            }
        }
    }
    if(fn&&report[0])state->FnUsed=1;
    if(!fn&&state->FnDown&&!state->FnUsed)result.FnTap=1;
    for(unsigned i=1;i<256;i++)if(!pressed[i])state->Actions[i]=0;
    state->FnDown=fn;state->LockDown=lock;
    report[8]&=(unsigned char)~0x0a;
    return result;
}
