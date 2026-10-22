# 财管 / Finances

Android 优先、离线存储的个人财务 App。阶段 2 已完成：四种项目、余额快照、独立收支、修改历史、首页排序、资产构成与真实趋势；Android API 36 模拟器验证通过。

首页右上角新建项目，点卡片进入详情；点记录编辑金额、时间、备注及查看历史。长按卡片只拖动排序，删除在详情确认。月度账单、备忘录和完整备份属于后续阶段；实际范围见 [阶段 2 交付与验证](docs/08_阶段2交付与验证.md) 和 [开发进度](docs/05_开发进度.md)。

## 运行

本工作区工具放在 `.tooling`，`scripts/environment.ps1` 配置当前 PowerShell 进程的路径。

```powershell
.\scripts\flutter.ps1 pub get
.\scripts\dart.ps1 run build_runner build
.\scripts\flutter.ps1 gen-l10n
.\scripts\start-emulator.ps1
.\scripts\flutter.ps1 devices
.\scripts\flutter.ps1 run -d emulator-5560
```

Android 最低版本为 10 / API 29，开发应用 ID 为 `com.example.finance_app`。

## 验证与构建

```powershell
.\scripts\check.ps1
.\scripts\flutter.ps1 test integration_test/asset_flow_test.dart -d emulator-5560 --no-pub
.\scripts\flutter.ps1 build apk --debug
```

阶段 2 安装包版本为 0.2.0+2，使用调试签名，不作为正式发布包。

已构建通用安装包：`artifacts/finance-stage2-debug.apk`（ARM32 / ARM64 / x86_64）。37 项主机测试、1 项安卓全流程及正常包原生分段复验通过；命令、日志和截图见文档 08。真机和最低 API 29 尚未实测；T02 完整账单流程留到阶段 3。

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
