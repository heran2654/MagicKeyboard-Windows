# MagicKeyboard-Windows

Apple Magic Keyboard（2024，蓝牙 PID `0320`）的 Windows x64 Fn 和功能键适配驱动。

**开发预览，尚无微软正式签名的可下载驱动。** 当前发布源码、构建与测试工具。普通安装器只接受微软签名包，不会开启测试模式、更改 Secure Boot 或导入本地证书。[English](docs/README.en.md)

## 功能

功能在内核过滤驱动与 Windows 自带 VHF 中执行，无需打开窗口或运行常驻适配程序。

| 操作 | 行为 |
|---|---|
| Fn＋Esc | 切换 Fn 反转模式，保存至服务注册表 |
| 普通模式 | F1–F12 为标准功能键；按住 Fn 使用下面的功能 |
| 反转模式 | F1–F12 使用下面的功能；按住 Fn 恢复标准功能键 |
| F1 / F2 | HID 亮度减 / 增，取决于显示设备和 Windows 支持 |
| F3 / F4 / F5 / F6 | 任务视图 / 搜索 / 语音输入 / 通知中心 |
| F7 / F8 / F9 | 上一首 / 播放暂停 / 下一首 |
| F10 / F11 / F12 | 静音 / 音量减 / 音量增 |
| Fn＋Backspace / Enter | Delete / Insert |
| Fn＋左 / 右 / 上 / 下 | Home / End / PageUp / PageDown |
| 单击 Fn | Windows＋Space，切换输入语言 |
| 右上角锁定键 | Windows＋L，锁定 Windows；不提供 Touch ID 指纹支持 |

## 支持范围与验证情况

仅匹配 `BTHENUM\{00001124-0000-1000-8000-00805f9b34fb}_VID&0001004c_PID&0320`。目前提供 x64 构建，未验证 USB、ARM64 或其他键盘型号。

基线 `0.5.0.1` 已在一台 Windows 11 Insider 设备上完成启动、虚拟 HID 枚举和一次设备重启。按键映射、报告边界及设备移除生命周期模拟测试通过。此前 `0.5.0.0` 在移除时清理顺序错误导致蓝屏，已修正，并加入回归测试。旧版 v2 的物理 Fn 和音量组合键得到用户确认；新纯驱动版的完整按键、休眠恢复、反复断连及长期稳定性仍需实机验证。

不宣称 WHQL/HLK 认证或普遍兼容性。签名不会替代稳定性测试。

## 构建与测试

安装 Visual Studio 2022 C++ 工具、Windows SDK 和 WDK（默认版本 `10.0.26100.0`）。在 PowerShell 中执行：

```powershell
./scripts/Test.ps1
./scripts/Build.ps1
./scripts/Prepare-Submission.ps1
```

支持通过 `-VCToolsRoot`、`-WindowsSdkRoot`、`-WindowsSdkLibRoot`、`-WdkRoot` 和 `-SdkVersion` 指定工具路径。路径不是系统环境变量，不会修改系统工具链。

构建产物在 `build/driver`，包含未签名 SYS、INF、CAT、PDB 和链接映射。送签 CAB 在 `dist`，需发布者进一步签名并提交微软。构建和测试脚本不安装驱动。生命周期测试使用模拟内核调用，不等于实机或 HLK 测试。

## 安装与卸载

**目前没有可直接执行此步骤的正式签名发布包。** 获得微软签名后，在管理员 PowerShell 中执行：

```powershell
./scripts/Install.ps1 -PackagePath C:/path/to/microsoft-signed-package
./scripts/Check-Driver.ps1 -RequireReady -RequireMicrosoftSigner
# 卸载本安装器记录的包：
./scripts/Uninstall.ps1
```

签名校验需要 Windows SDK 的 SignTool，可通过 `-SignToolPath` 指定。安装器拒绝覆盖已有 AppleKeyboardFilter 或未知过滤器，以保留既有驱动配置。旧本地测试版请使用其原安装包中的卸载器先卸载。安装状态保存在本地 `.local`，不应提交到 Git。

开发者自行进行本地测试签名时，应使用专用测试机器；本仓库不分发本机测试证书或私钥，也不提供绕过正式安装器签名校验的开关。

## 正式签名与发布

详见 [签名流程](docs/SIGNING.md)、[实机测试清单](docs/VALIDATION.md) 和 [发布记录](CHANGELOG.md)。正式目标是完成 HLK 测试并通过微软硬件开发者后台签名，之后发布可在标准 Windows 签名策略下安装的包。

## 来源与许可证

基于 [sheehanmunim/apple-peripherals-for-windows](https://github.com/sheehanmunim/apple-peripherals-for-windows) 的键盘过滤驱动，基线提交 `238f036ebcb66799e39e821f302e76fb21c2f15c`；继承 GPL-2.0 许可证。其底层过滤方案参考 [samartzidis/WinAppleKey](https://github.com/samartzidis/WinAppleKey)，MIT 通知保留在 [third-party/WinAppleKey-LICENSE](third-party/WinAppleKey-LICENSE)。详见 [第三方说明](THIRD_PARTY.md)。本项目与 Apple、Microsoft 无隶属关系。
