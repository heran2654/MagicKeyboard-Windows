#include "../src/AppleKeyboardFilter.Driver/ActionEngine.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
int main(void){
 ACTION_STATE s={0}; ACTION_RESULT r; unsigned char p[9];
 memset(p,0,9);p[2]=0x45;p[8]=2;r=ProcessActionReport(&s,p);assert(r.ConsumerBits==0x80&&p[2]==0);
 memset(p,0,9);p[2]=0x45;r=ProcessActionReport(&s,p);assert(r.ConsumerBits==0x80&&!r.FnTap);
 memset(p,0,9);r=ProcessActionReport(&s,p);assert(!r.ConsumerBits);
 memset(&s,0,sizeof(s));s.Inverted=1;memset(p,0,9);p[2]=0x45;r=ProcessActionReport(&s,p);assert(r.ConsumerBits==0x80);
 memset(p,0,9);ProcessActionReport(&s,p);memset(p,0,9);p[2]=0x45;p[8]=2;r=ProcessActionReport(&s,p);assert(!r.ConsumerBits&&p[2]==0x45);
 memset(&s,0,sizeof(s));memset(p,0,9);p[2]=0x29;p[8]=2;r=ProcessActionReport(&s,p);assert(s.Inverted&&r.InversionChanged&&p[2]==0);
 memset(p,0,9);p[2]=0x29;p[8]=2;r=ProcessActionReport(&s,p);assert(s.Inverted&&!r.InversionChanged);
 memset(&s,0,sizeof(s));memset(p,0,9);p[8]=2;r=ProcessActionReport(&s,p);assert(!r.FnTap);memset(p,0,9);r=ProcessActionReport(&s,p);assert(r.FnTap);
 memset(&s,0,sizeof(s));memset(p,0,9);p[0]=2;p[2]=0x50;p[8]=2;ProcessActionReport(&s,p);assert(p[0]==2&&p[2]==0x4a);
 memset(&s,0,sizeof(s));memset(p,0,9);p[8]=8;r=ProcessActionReport(&s,p);assert(r.LockTap&&p[8]==0);p[8]=8;r=ProcessActionReport(&s,p);assert(!r.LockTap);
 memset(p,0,9);ProcessActionReport(&s,p);p[8]=8;r=ProcessActionReport(&s,p);assert(r.LockTap);
 memset(&s,0,sizeof(s));memset(p,0,9);p[2]=0x04;p[8]=2;ProcessActionReport(&s,p);assert(p[2]==0x04);memset(p,0,9);r=ProcessActionReport(&s,p);assert(!r.FnTap);
 memset(&s,0,sizeof(s));memset(p,0,9);p[2]=0x3c;p[8]=2;ProcessActionReport(&s,p);assert(p[0]==8&&p[2]==0x2b);
 puts("PASS: Fn modes, held-key stability, Fn+Esc edge, Fn tap, navigation, lock edges, standard keys, Win shortcuts");return 0;
}
