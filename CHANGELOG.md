# Changelog

## 0.5.0.1 — source preview

- Handle Fn, function-key inversion, navigation, media, input-language switching and lock through a kernel filter and VHF; no companion process required.
- Persist inversion selected by Fn+Esc.
- Correct removal ordering: stop input submission and delete VHF before forwarding REMOVE_DEVICE; drain queued work before freeing it.
- Add production-function lifecycle regression tests and report/action tests.
- Add reproducible x64 build, submission CAB preparation, Microsoft-signature verification and recorded-package install/uninstall scripts.
- Publish source only. Microsoft signing, HLK and the full hardware validation matrix are pending.

## 0.5.0.0 — local experiment, not published

- Initial VHF implementation. Device removal could use an already-destroyed lower WDF device and crash with bugcheck 0x50; superseded by 0.5.0.1.
