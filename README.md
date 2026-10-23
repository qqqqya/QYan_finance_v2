# 财管 / Finances

Android 优先、离线存储的个人财务 App。当前版本 0.5.1+6：项目/余额、独立收支、月度账单、分类管理、年度汇总、备忘录、修改历史、首页排序、资产构成、直线趋势及完整本地备份恢复；含 v0.0/v1/v2 兼容、四配色和分批明细加载。

首页右上角新建项目；卡片进入详情，正文长按/更多打开菜单；独立把手按住排序，删除需再次确认。月度账单和备忘录与资产独立。设置 → 数据管理可导出 .moneybak、系统分享、覆盖恢复、管理私有恢复副本及恢复出厂。本轮交互、迁移及实际验证见 [文档 16](docs/16_账单主题与项目交互优化.md)，阶段 5 历史见 [文档 13](docs/13_阶段5验收与交付.md)、[开发进度](docs/05_开发进度.md)；长期字段契约见 [backup-format.md](docs/backup-format.md)。真机最终验收仍待补。

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
.\scripts\flutter.ps1 test integration_test/ledger_flow_test.dart --device-id=emulator-5560
.\scripts\flutter.ps1 build apk --debug
.\scripts\flutter.ps1 build apk --release
```

现有 Android Studio 旧版更新优先选择 artifacts/finance-0.5.1-ide-debug.apk；旧脚本签名使用 artifacts/finance-0.5.1-debug.apk。正式密钥签名的 release 候选为 artifacts/finance-0.5.1-release.apk，不能直接覆盖不同调试签名。安装与本地密钥备份见 [文档 14](docs/14_签名与安装.md)。正常同签名覆盖升级保留数据；数据库 v3，备份格式 v2（兼容 v0.0/v1）。

本轮完整主机回归 525 项通过（93 通用 + 432 四配色布局），静态/Schema、两条 Android 集成、真实文件恢复/导出、同签名覆盖升级和冷启动均通过。截图后把手底部对齐又做了 93 通用及 12 组定向布局、Android 与最终 Release 复验。真实结果和原始失败/重试记录见文档 16；阶段 5 的性能指标仅是历史数据，真机仍未验收。

Flutter 测试与构建按顺序执行；切换 debug/release 时正常运行构建以生成对应插件注册文件，不跳过 pub，也不升级锁定依赖。签名目录 .signing 不在 Git 内，需自行离线备份；本项目不自动发布。

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
- `lib/data`：8 张业务/设置表、1 张本地备份辅助表、事务、v1/v2→v3 迁移、默认数据与数据仓库。
- `lib/services` 和 Android 原生桥接：SAF 文件读写、FileProvider 分享、备份工作流；无服务器或同步。
- `lib/app`、`lib/ui`：共享状态、主题三语、项目/记录/历史/排序/总览及设置。
- `lib/l10n`：简中、繁中、英文 ARB 与生成的资源。
- `test`、`integration_test`：逻辑、数据库、组件和安卓冒烟测试。
- `docs`：编号规划、实际运行记录、备份 Schema 和最小样例；[阅读索引](docs/00_阅读索引.md)。

月度账单、独立收支与资产余额互相独立；余额记录保存某时刻余额，金额按整数分计算。数据库是页面汇总的事实来源。
