# 财管 / Finances

Android 优先、离线存储的个人财务 App。当前版本 0.3.0+3：项目/余额、独立收支、月度账单、分类管理、年度汇总、备忘录、修改历史、首页排序、资产构成和直线趋势。

首页右上角新建项目；卡片进入详情，长按只排序。月度账单和备忘录从首页单独进入，与资产独立。正式备份仍属阶段 4。实际范围见 [阶段 3 交付与验证](docs/09_阶段3交付与验证.md)、[开发进度](docs/05_开发进度.md)。

## 运行

本工作区工具放在 `.tooling`，`scripts/environment.ps1` 配置当前 PowerShell 进程的路径。

```powershell
.\scripts\flutter.ps1 pub get
.\scripts\dart.ps1 run build_runner build
.\scripts\flutter.ps1 gen-l10n
.\scripts\start-emulator.ps1
.\scripts\flutter.ps1 devices
.\scripts\flutter.ps1 run --device-id=emulator-5560
```

Android 最低版本为 10 / API 29，开发应用 ID 为 `com.example.finance_app`。

## 验证与构建

```powershell
.\scripts\check.ps1
.\scripts\flutter.ps1 test integration_test/ledger_flow_test.dart --device-id=emulator-5560 --no-pub
.\scripts\flutter.ps1 build apk --debug
```

阶段 3 为调试功能测试包。现有 Android Studio 安装优先选择 artifacts/finance-stage3-ide-debug.apk；脚本/旧交付签名选择 artifacts/finance-stage3-debug.apk。两包同代码、不同既有调试签名；不要用卸载绕过更新冲突。

52 项主机测试、1 项安卓业务全流程通过；T02 已覆盖账单增改删独立性。原生与覆盖升级的真实结果见文档 09；[模拟器和手机安装方法](docs/10_模拟器与手机APK验证.md)单独列出。真机和最低 API 29 尚未实测。

本次模拟器以后台模式运行。若需要打开模拟器窗口，先在 PowerShell 执行：

```powershell
. .\scripts\environment.ps1
& "$env:ANDROID_HOME\platform-tools\adb.exe" -s emulator-5560 emu kill
.\scripts\start-emulator.ps1
```

Android Studio 的 Flutter SDK 设为 `D:\Finance\.tooling\flutter`，Android SDK 设为 `D:\Finance\.tooling\android-sdk`。脚本默认使用 Flutter 文档列出的 CFUG 引擎镜像，仅作用于当前进程；完整说明见文档 06。

## 结构

- `lib/core`：整数分、业务日期/时间。
- `lib/domain`：余额快照、真实趋势与设置模型。
- `lib/data`：8 张业务表、事务、迁移骨架、默认数据与数据仓库。
- `lib/app`、`lib/ui`：共享状态、主题三语、项目/记录/历史/排序/总览及设置。
- `lib/l10n`：简中、繁中、英文 ARB 与生成的资源。
- `test`、`integration_test`：逻辑、数据库、组件和安卓冒烟测试。
- `docs`：编号规划、实际运行记录、备份 Schema 和最小样例；[阅读索引](docs/00_阅读索引.md)。

月度账单、独立收支与资产余额互相独立；余额记录保存某时刻余额，金额按整数分计算。数据库是页面汇总的事实来源。
