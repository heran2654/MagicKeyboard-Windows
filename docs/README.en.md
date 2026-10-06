# MagicKeyboard-Windows

Windows x64 kernel filter for Bluetooth Apple Magic Keyboard 2024, PID 0320. Fn+Esc switches and persists function-key inversion; the lock key sends Win+L. Navigation, media keys and Windows shortcuts run through the physical report and Windows VHF without a resident companion process.

This is a source-only developer preview. There is no Microsoft-signed downloadable driver yet. The public installer requires valid Microsoft hardware-dashboard signatures and never enables test-signing, imports a local certificate or changes Secure Boot. Signing does not certify stability.

Run `scripts/Test.ps1` and `scripts/Build.ps1` with Visual Studio C++ tools, Windows SDK and WDK 10.0.26100.0. Explicit toolchain paths are supported. Run `scripts/Prepare-Submission.ps1` to prepare an unsigned submission CAB; an authorized publisher must sign and submit it. Artifacts remain under ignored build/dist directories.

The 0.5.0.1 baseline passed unit and mocked production PnP lifecycle tests. One Windows 11 Insider system completed startup, VHF enumeration and a device restart. Full physical-key, sleep/resume, reconnect and long-running validation is pending. Version 0.5.0.0 crashed after forwarding REMOVE_DEVICE before VHF cleanup; the corrected ordering is covered by the lifecycle regression.

Once a Microsoft-signed package exists, run Install.ps1 in an elevated terminal, then Check-Driver.ps1. Uninstall.ps1 removes only the package recorded by this installer. Existing filters require review and are not overwritten. USB, ARM64, other keyboard models and Touch ID fingerprint recognition are not supported by this release.

Derived from apple-peripherals-for-windows at 238f036ebcb66799e39e821f302e76fb21c2f15c under GPL-2.0, retaining WinAppleKey MIT attribution. See the root README, LICENSE, THIRD_PARTY.md and docs/SIGNING.md.
