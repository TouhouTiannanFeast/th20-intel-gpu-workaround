TH20 Intel graphics crash workaround v1

用途：Intel 核显与 NVIDIA/AMD 显卡并存的 Windows 10/11 电脑，
为选定的 th20.exe 设置 Windows“高性能”显卡偏好，绕过核显渲染路径。
它不是 Intel 驱动修复，不适用于只有 Intel 显卡的电脑。
多显卡电脑具体使用哪块显卡仍由 Windows 决定。

使用：
1. 解压到可写的普通文件夹，完整保留本包。
2. 正常退出 TH20。
3. 双击 Apply.cmd，在文件选择框中选择实际的 th20.exe。
4. 重新启动游戏，确认画面、声音和进入关卡正常。

回退：双击 Restore.cmd，选择相同路径的 th20.exe。
原设置记录在本包 backups 文件夹中，请保留它以便回退。
若设置已被其他工具更改，回退会停止，避免覆盖新设置。
重复应用保留首次备份。游戏移动后需对新路径重新应用。
若原先已设为高性能，本工具会提示无需修改，不创建回退备份。

修改范围：仅当前用户的
HKCU\Software\Microsoft\DirectX\UserGpuPreferences
中以所选 th20.exe 完整路径为名的字符串，设置 GpuPreference=2;。
无需管理员权限。不替换游戏或驱动文件，不修改存档和窗口位置，不关闭游戏进程。
PowerShell 的执行策略选项仅作用于本次脚本进程，不更改系统执行策略。

命令行检查（只读）：
powershell.exe -NoProfile -File .\TH20-GPU.ps1 -Action Status -GameExe "D:\Games\th20\th20.exe"
预演（不写设置或备份；硬件检查在实际应用时执行）：
powershell.exe -NoProfile -File .\TH20-GPU.ps1 -Action Apply -GameExe "D:\Games\th20\th20.exe" -WhatIf

仅核显机器：本工具不能提供另一块 GPU，因此不能解决该情况。
本包未包含或验证 DXVK、dgVoodoo 等渲染替换方案。

脱敏后的故障参考与检索结果见 REPORT.md。
backups 文件夹含运行者选择的游戏完整路径、原设置与操作时间，勿上传或转发。
本工具不联网、不上传诊断信息。公开发行包不含运行备份。
