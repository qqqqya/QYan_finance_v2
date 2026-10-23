# 10 · 模拟器与手机 APK 验证

本页保留阶段 3（2026-10-22）的环境与手工验证方法；最新阶段 5 包、验收和签名见 13、14，备份换机见 12。后文 stage3 命令是历史记录，当前更新应选择 stage5 对应签名的包。所有命令在 D:\Finance 的 PowerShell 执行。

## 1. 你现有环境的结论

截图的 Flutter、Android Studio、Android SDK 和运行环境可继续用；本次本机 doctor 的 Android 工具链检查通过，API 36 实际构建通过。无需为此阶段另装软件。

- Android Studio：Flutter SDK 用 D:\Finance\.tooling\flutter，Android SDK 用 D:\Finance\.tooling\android-sdk；运行入口 lib/main.dart。
- 截图列出的 ANDROID_HOME、ANDROID_SDK_ROOT、FLUTTER_STORAGE_BASE_URL、GRADLE_USER_HOME、JAVA_HOME、PUB_CACHE 与项目脚本一致。
- 设备列表选择 Android 手机/模拟器。Chrome、Edge、Windows 是其他目标，不是 Android 安装验证；缺少 Visual Studio 只影响 Windows 桌面构建。
- SDK Manager 的 Partially installed 不能单独判断工具链缺失，可能只是同一 API 的可选镜像/组件未全装。以实际 doctor、构建和目标设备运行结果判断；无需勾选所有 Android 版本。API 37 模拟器可运行目标 API 36 的本应用，不要求编译 SDK 改到 37。

~~~powershell
.\scripts\flutter.ps1 doctor --verbose
.\scripts\flutter.ps1 devices
.\scripts\check.ps1
~~~

只分享检查结论，不分享完整环境变量截图、私钥或密码。

## 2. 当前包与更新签名

本机确有两套已有调试密钥，证书不同：

| 测试包 | 对应安装来源 | 证书 SHA-256 前缀 |
|---|---|---|
| artifacts/finance-stage3-ide-debug.apk | 当前 Android Studio 直接 Run 的 API 37 应用；优先供你验证更新 | 62d56913337a |
| artifacts/finance-stage3-debug.apk | 之前交付 APK / 项目脚本构建 | ca5a2b7fbaa1 |

两包版本和应用代码一致、签名不同。证书匹配才可覆盖更新保留数据。用户 API 37 上已安装应用的公开证书已只读确认匹配 IDE 包；没有对该设备进行更新安装。完整包摘要、版本和签名见 stage3-apk-manifest.json。

如果显示 UPDATE_INCOMPATIBLE 或 VERSION_DOWNGRADE，停止安装，不要卸载、清数据或使用降级参数绕过。先核对包的签名和版本。正式备份尚未实现，卸载会丢失本地记录。未来发行签名在阶段 5 单独固定；本机调试密钥不要删除、分享或提交 Git。

IDE 若改用项目脚本启动，应同时留意 ANDROID_USER_HOME 不同可能选用另一套调试签名。继续当前 IDE 的运行方式即可；仅切换 SDK 路径并不能统一已有签名。

## 3. 现在：模拟器验证普通 APK

可直接把 IDE 兼容 APK 拖入你已运行的 API 37 模拟器安装，再从应用图标打开；不要仅凭热重载判断持久化。

也可指定设备安装，脚本只覆盖安装，不执行卸载或清库：

~~~powershell
.\scripts\install-android.ps1 -Device emulator-5554 -Apk .\artifacts\finance-stage3-ide-debug.apk -Launch
~~~

本次自动化专用设备为 Finance_API_36 / emulator-5560。verify-stage3-android.ps1 和 verify-stage3-upgrade.ps1 会创建、删除 QA 数据，其中升级脚本会重置测试应用，只能用于该专用设备，禁止拿它们跑有重要数据的设备。

## 4. 之后：手机上安装

手机直接安装 APK 不需要安装 Android Studio 或 Flutter。将 IDE 兼容测试 APK 传到手机，核对文件名/版本，从手机文件管理器打开；按系统提示仅为该文件来源开启“允许安装未知应用”，安装完成后可关闭该来源权限。不同厂商的菜单名称可能不同。

如果需要连接电脑排错，手机打开开发者选项和 USB 调试，用数据线连接，在手机上确认此电脑的授权。Windows 仅在设备识别需要时安装手机厂商官方 USB 驱动，届时再按具体机型告知；现在不安装驱动。[Android 真机连接说明](https://developer.android.com/studio/run/device)

~~~powershell
. .\scripts\environment.ps1
& "$env:ANDROID_HOME\platform-tools\adb.exe" devices
# 将下一行的 手机设备ID 替换为上一步状态为 device 的真实 ID
.\scripts\install-android.ps1 -Device 手机设备ID -Apk .\artifacts\finance-stage3-ide-debug.apk -Launch
~~~

unauthorized 先看手机授权弹窗；offline 检查连接，不反复卸载应用。多设备时必须指定 ID。[ADB 官方说明](https://developer.android.com/tools/adb)

当前交付为调试功能包。性能与日用发行验收应在后续固定签名的 release 包上单独做；不能用调试包或模拟器耗时代表手机性能。[Flutter Android 构建与签名](https://docs.flutter.dev/deployment/android)

## 5. 一次可复现的手工验收

在模拟器先走一遍，手机接入后原样复验。使用可辨认的测试记录，记录预期与实际，不只记录“点了没报错”。

| 步骤 | 操作与预期 |
|---|---|
| 余额及斜线 | 测试资产在三个日期记录 100/500/1000；当前为 1000，图中点等距、直线连接；打开时点金额检查日期和金额 |
| 账单独立 | 在资产 1000 时新增支出 100，资产保持 1000；独立收入记 7.77 也不进入账单 |
| 历史月份 | 选上月新增；默认日期必须在上月。另用过去的 2024/2/29 和 2025/2/28 测试 |
| 跨月跨年 | 将上月支出改到本月、再改成去年收入；分类重新选择，原月、新月、两年汇总均正确 |
| 切换与零记录 | 切换收入/支出图和明细，再切全部；删除该方向最后一笔后显示空状态 |
| 分类 | 改名、停用一个有账单的分类；旧账单仍显示，新账单不能选；迁移删除后金额和日期不变 |
| 备忘录 | 标题、正文、日期、两个标签；关键词+标签组合筛选；编辑后可看历史，删历史内容不变 |
| 重启保存 | 保存后离开 App、从最近任务移走，再打开；连接 ADB 时可 force-stop 后从图标启动。核对金额、备注、账单、备忘录、历史删除、语言和主题 |
| Android 操作 | 左右边缘返回、键盘先关闭、未保存继续/放弃/保存；普通横滑不退桌面 |
| 外观 | 简中/繁中/英文、浅色/深色/跟随系统、150%/200% 字号、键盘遮挡；自定义文字保持原文 |
| 覆盖升级 | 已有测试数据时安装同签名高版本；ID、记录、备注、历史和设置保留。不能以卸载重装当升级成功 |

记录模板：日期、包版本及 SHA-256、模拟器/手机型号、Android/API、屏幕/字号、语言/主题、步骤、预期、实际、通过/失败/未测、截图或日志路径。

目前手机各项状态均为“未测”。本阶段不进行正式备份/恢复出厂测试，也不将这份清单本身当作验收证据。
