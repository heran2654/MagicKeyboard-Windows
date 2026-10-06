#ifdef APPLE_REPORT_UNIT_TEST
#include "ReportTestTypes.h"
#else
#include "Driver.h"
#endif

VOID ProcessAppleKeyboardReport(_Inout_updates_bytes_(Size) PUCHAR Report, _In_ ULONG Size)
{
    if (Report == NULL || Size != 9 || !g_EmitFnAsMenu || (Report[1] & ~0x01) != 0 ||
        (Report[8] & ~0x0B) != 0)
    {
        return;
    }

    PUCHAR keySlots = &Report[2];
    PUCHAR specialKey = &Report[8];
    if ((*specialKey & AppleSpecialFnMask) == 0)
    {
        return;
    }

    BOOLEAN alreadyPresent = FALSE;
    for (ULONG index = 0; index < 6; index++)
    {
        if (keySlots[index] == HidMenu)
        {
            alreadyPresent = TRUE;
            break;
        }
    }

    if (!alreadyPresent)
    {
        for (ULONG index = 0; index < 6; index++)
        {
            if (keySlots[index] == HidKeyNone)
            {
                keySlots[index] = HidMenu;
                break;
            }
        }
    }

    *specialKey &= ~AppleSpecialFnMask;
}

BOOLEAN TryProcessAppleKeyboardTransportBuffer(_Inout_updates_bytes_(Size) PUCHAR Buffer, _In_ ULONG Size, _In_ ULONG PrefixBytes)
{
    const ULONG keyboardReportBodyLength = 9;
    if (Buffer == NULL || PrefixBytes > 2 || PrefixBytes == 0 ||
        Size != PrefixBytes + keyboardReportBodyLength)
    {
        return FALSE;
    }

    // Bluetooth HID DATA/Input followed by keyboard report ID 1.
    // USB report ID 1. Never rewrite feature, battery or control reports.
    if ((PrefixBytes == 2 && (Buffer[0] != 0xA1 || Buffer[1] != 0x01)) ||
        (PrefixBytes == 1 && Buffer[0] != 0x01))
    {
        return FALSE;
    }

    ProcessAppleKeyboardReport(Buffer + PrefixBytes, keyboardReportBodyLength);
    return TRUE;
}
