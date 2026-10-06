#include <stdint.h>
typedef unsigned char UCHAR, *PUCHAR, BOOLEAN;
typedef uint32_t ULONG;
#define VOID void
#define TRUE 1
#define FALSE 0
#ifndef _Inout_updates_bytes_
#define _Inout_updates_bytes_(x)
#endif
#ifndef _In_
#define _In_
#endif
enum { HidKeyNone = 0, HidMenu = 0x65, AppleSpecialFnMask = 2 };
extern ULONG g_EmitFnAsMenu;
