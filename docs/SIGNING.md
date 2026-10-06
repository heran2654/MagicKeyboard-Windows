# 正式签名路线

目前只有本地开发测试版本，尚未获得微软硬件开发者后台签名。不要把自签名、EV 对提交文件的签名或 GitHub Release 标签描述为微软认证。

## 必要条件

发布者需要注册 Microsoft Hardware Developer Program，并在账号关联有效 EV 代码签名证书。身份验证、证书持有者授权和微软审批由真实发布者完成；私钥不得放入仓库或发布资产。[微软账号流程](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/)、[证书要求](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-reqs)。

## 目标：HLK 测试与后台签名

1. 在支持的标准 Windows 版本及测试设备上完成实机验证，并按当前 HLK 要求运行测试。
2. 保存源代码提交号、构建工具版本、二进制哈希及 PDB。
3. 由持证发布者签名提交材料，并在硬件开发者后台提交驱动及 HLK 日志。
4. 下载微软签名后的包，不再修改 INF/SYS/CAT。
5. 运行 `Verify-SignedPackage.ps1`，再在没有测试签名模式的干净设备上验证安装、运行、断连、恢复和卸载。
6. 发布带源码标签、签名说明、校验和及实机验证结果的二进制版本。

HLK 是微软推荐的完整发布路线。[签名选项](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/driver-signing-offerings)、[HLK 入门](https://learn.microsoft.com/en-us/windows-hardware/test/hlk/getstarted/windows-hlk-getting-started)。

## Attestation 的边界

Attestation 不需要 HLK 日志，但仍需要硬件开发者账号和相关 EV 证书。它表示 Windows 信任微软签过的驱动，不表示 Windows Certified，也不验证功能正确性。微软当前文档将它定位为测试场景；不能用于面向普通用户的 Windows Update 分发。本项目不会把这条路径称为完成正式兼容性认证。[官方要求](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-attestation)。

`Prepare-Submission.ps1` 只生成候选 CAB，不代替提交审核，也不生成 HLK 结果。取得签名前，本仓库仅发布源码预览。
