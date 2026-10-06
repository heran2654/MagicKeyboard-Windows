# Apple Keyboard Filter

This fork targets Bluetooth Magic Keyboard PID 0320 on x64 Windows. It reads the Apple Fn and lock flags, remaps keyboard navigation and Windows shortcuts in the physical report, and submits media/brightness and Fn-tap/lock shortcuts through a VHF keyboard and consumer device. Fn+Esc toggles the function-key mode and saves it in the service registry.

No companion process is required when VHF initialization succeeds. The legacy fallback emits the supported Menu usage; it is retained for development recovery and is not the normal standalone operation. Installer checks must require VHF initialization and both virtual collections.

The driver derives from apple-peripherals-for-windows and the MIT-licensed WinAppleKey filter approach. See the repository LICENSE and third-party notices. Public binary installers require a Microsoft hardware-dashboard signed package. Source availability does not imply a production signature or HLK certification.

During removal, stop report submission and complete VhfDelete while the lower VHF device is still alive, then forward REMOVE_DEVICE. Release work-item resources only after outstanding requests drain. Test-Lifecycle.ps1 compiles these production removal functions against a mock lower device to check this ordering.
