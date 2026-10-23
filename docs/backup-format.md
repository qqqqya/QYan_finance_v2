# JSON 备份格式与兼容契约

规范版本：v2；更新：2026-10-23。适用于 finance-backup，正式文件扩展名 .moneybak，内容为完整 UTF-8 JSON。此文档与 JSON Schema、冻结样例、迁移测试共同构成格式契约；变更任何格式时必须同时更新，不能只改导入器或导出器。

## 三种版本分别管理

| 标识 | 含义 | 当前值 |
|---|---|---|
| schemaVersion | **独立备份格式版本号**，等价于需求中 backupFormatVersion 的概念；沿用已交付字段，不另行改名 | 整数 2 |
| appVersion | 导出应用的软件版本，仅供定位问题，不决定正常备份迁移 | 0.5.1+6 |
| SQLite user_version | 手机数据库结构版本，不是 JSON 格式版本 | 3 |

无版本字段的本项目完整备份按用户决定识别为 **v0.0**（迁移器内部编号 0），导出统一使用 schemaVersion: 2。backupFormatVersion 仅作为导入字段别名接受，必须为整数；两个版本字段同时出现时必须相同。正式导出继续只写 schemaVersion。当前读取器兼容 v0.0/v1/v2；旧读取器看到 v2 应提示升级，不能保证旧软件能够读取新格式。

软件版本更新不必递增备份版本。只要字段、类型、含义、单位、枚举和校验规则不变，保持原格式版本；本次新增配色属于严格旧解析器不支持的字段，因此升级为 v2。新增字段、删除/重命名字段、改变金额单位、日期表示或枚举等会影响严格旧解析器时，必须递增格式版本，提供逐级迁移器并保留旧样例。不能用同一版本号重新解释原字段。

## 完整文件头

| 字段 | JSON 类型 | 约定 |
|---|---|---|
| format | string | 固定 finance-backup；不能靠扩展名识别 |
| schemaVersion | integer | 当前 2，独立于软件和数据库版本 |
| appVersion | string | 导出软件版本，最长 64 |
| exportedAt | string | UTC ISO 8601，Z 结尾，毫秒精度；导出使用 YYYY-MM-DDTHH:mm:ss.SSSZ |
| currency | string | 固定 CNY |
| timeZone | string | 可识别的 IANA 账本时区；与 data.settings.timeZone 相同 |
| data | object | 下列七个业务集合及 settings 全部存在，即使集合为空也写 [] |
| checksum | object | algorithm 固定 SHA-256；value 为 64 位小写十六进制 |

校验算法：移除顶层 checksum → 所有对象的键递归按 UTF-16 字符串顺序排序 → 数组保持原顺序 → 紧凑 JSON → UTF-8 → SHA-256。空白/缩进不影响校验；数组和业务值改变会影响校验。先验证原文件校验和，再进行迁移，绝不为校验失败文件重新签算后强行接受。校验和检测损坏，不提供加密或身份认证。

v1 的规范字符串编码沿用 Dart jsonEncode：非 ASCII 文字直接写 UTF-8，控制字符、引号及反斜线按 JSON 规则转义，斜线不额外转义；整数以完整十进制表示，不用科学计数法或浮点数。对象键使用 Dart String.compareTo 的 UTF-16 顺序，布尔及 null 使用 JSON 小写字面量。未来跨平台实现必须用冻结样例逐字节核对哈希，不能把其他库默认的 ASCII 转义或数字格式当作同一算法。

## data 字段

六类业务对象统一包含 id、createdAt、updatedAt：id 为稳定 UUID 字符串，时间为 UTC ISO 8601 / Z / 毫秒精度。EditHistory 使用独立的 changedAt，Settings 不含这些字段。UUID 全文件唯一；导入不生成替代 ID，不因名称相同合并。

| 集合 | 额外字段（类型） | 业务含义 |
|---|---|---|
| projects | type(string)、nameKey(string/null)、customName(string/null)、categoryKey(string)、iconKey(string)、colorKey(string)、includeInSummary(boolean)、sortOrder(integer)、note(string) | type 为 asset / liability / income_log / expense_log；名称至少一项存在，customName 为原文；独立收支项目 includeInSummary 必须 false |
| balanceRecords | projectId(string)、balanceMinor(integer)、businessDate(string)、businessTime(string)、orderKey(integer)、note(string) | 仅引用资产/负债；金额为余额快照，不能相加；业务时刻相同时同项目 orderKey 较大者生效，导入保留 |
| projectEntries | projectId(string)、amountMinor(integer)、businessDate(string)、businessTime(string)、note(string) | 仅引用独立收入/支出项目；方向继承项目，现存记录逐笔累加 |
| bills | type(string)、amountMinor(integer)、categoryId(string)、businessDate(string)、businessTime(string)、note(string) | type 为 income / expense，分类方向必须一致；没有账户或项目关联，不改资产余额 |
| categories | type(string)、nameKey(string/null)、customName(string/null)、sortOrder(integer)、isActive(boolean) | 账单分类，type 为 income / expense；停用分类仍可被旧账单引用 |
| memos | title(string)、body(string)、businessDate(string)、tags(array of string) | 备忘录原文与标签，不影响财务金额 |
| editHistory | id(string)、entityType(string)、entityId(string)、changedAt(string)、before(object)、after(object) | entityType 为 project / balanceRecord / projectEntry / bill / category / memo；必须引用现存所属对象；前后差异原样保留 |
| settings | themeMode(string)、languageMode(string)、currency(string)、timeZone(string)、themeColor(string) | 主题 system/light/dark；语言 system/zh-Hans/zh-Hant/en；币种与时区与头部一致；v2 新增 themeColor，枚举 red / green / purple / blue |

所有金额使用整数分，例如 12.34 元为 1234，拒绝 1234.0 等浮点表示。余额允许 0；收支必须大于 0；单条上限 999999999999 分。业务日期严格 YYYY-MM-DD、1900–9999 的真实日历日期；业务时间 HH:mm，按账本时区校验非未来时间。月份由业务日期决定，createdAt 不参与月份归属。

sortOrder 为项目集合/分类集合内唯一的非负 64 位整数；orderKey 为同项目内唯一的非负 64 位整数。汇总金额、当前余额、变化额、图表、统计缓存不导出，恢复后从业务事实重新计算。

nameKey 是内置名称键，用户名称/备注不翻译。categoryKey 的 custom: 前缀保留用户分类原文。数据库 memos.tagsJson 在文件中是 tags 数组；历史 beforeJson/afterJson 在文件中是 before/after 对象；数据库 createdAtMs/updatedAtMs 转为上述 UTC 字符串。不能把数据库列名直接替换成新的文件字段。

历史快照可含已经删除分类的 categoryId 和 categoryNameKey/categoryCustomName 名称快照，这些快照引用不作为现有分类外键；历史自身 entityId 必须有效。历史金额仍是整数分。删除业务对象会清理所属历史；删除历史不改变业务金额。

名称上限 80、标题 200、备注 2000、备忘录正文 20000（应用按 UTF-16 长度检查）；标签最多 10 个、每个最多 30、不得重复。正式导入导出均限 32 MiB UTF-8，七类业务集合合计 100000 条，历史嵌套最多 24 层。完整结构见 [当前 v2 Schema](backup/finance-backup-v2.schema.json)，[冻结 v1 Schema](backup/finance-backup-v1.schema.json)。

## 版本变化与导入流程

| 来源 | 识别条件 | 转换与保护 |
|---|---|---|
| v0.0 | 没有任何版本字段，或显式整数 0；其余必须是本项目完整 finance-backup 结构 | 0→1→2：添加格式版本/规范校验和，再仅补非财务设置 themeColor=blue，原有字段原样保留；不补表、不补 ID、不猜金额。原文件若有校验和必须先通过；无校验和须在覆盖预览中提示 |
| 早期 v1 样例 | 已知 0.1.0–0.3.0 项目版本的完整 v1 形状，没有校验和 | 保留历史协议样例的兼容入口，完整业务校验后生成规范校验和；预览明确无法验证原始完整性。这是历史例外，不允许现代 v1 缺校验和自动降级 |
| 正式 v1 | schemaVersion: 1 + 有效校验和 | 校验原文件后 1→2，仅增加 themeColor=blue，金额、ID、顺序和已有设置原样保留；阶段 4/5 导出文件继续支持 |
| 正式 v2 | schemaVersion: 2 + 有效校验和 + 完整 settings.themeColor | 不转换业务结构，严格校验、预览后整体替换 |
| 未实现的更高版本 | 格式版本 >2 | 提示先升级本应用；不尝试导入、不改原库 |

本次 0.5.1 首次发布格式 v2，新增且仅新增 settings.themeColor，其他业务结构不变。v1 的设置必须恰好包含原四项，不能把已经带 themeColor 的文件伪装成 v1；v2 缺少该字段或枚举未知均拒绝。转换默认蓝色仅适用于原本没有此概念的旧格式，不猜补任何财务事实。数据库 2→3 也只添加带 blue 缺省值的列，不重排已有项目。

将来发布 v3 必须实现并测试 2→3，使 v0.0/v1/v2 都能逐级恢复。迁移只操作内存候选数据；原文件、现有数据库与私有恢复副本不在校验/确认前改变。原始校验和先校验，通过转换后再生成当前格式校验和；不能用新校验和掩盖损坏。

流程：检查资源与版本 → 校验原始校验和（如存在）→ 逐级转换 → 严格结构/类型/日期/金额/引用检查 → 显示来源格式、数量、金额及设置预览 → 用户确认 → SQLite 同事务生成恢复副本并整体替换 → 刷新页面。失败全部回滚，重复恢复不叠加。无校验和的 v0.0 只能确认结构和业务合法，不能保证文件未曾被改动。

私有恢复副本、最近导出的设备 URI/位置、分享缓存和操作日志不进入文件；防止递归副本及跨设备失效路径。恢复出厂清除私有数据与副本，保留用户选定位置的外部备份。

## 后续修改的必做检查

1. 提交格式变化说明、当前版本、逐级迁移器和 Schema；任何不兼容改动必须更改格式版本。
2. 保留 test/fixtures/backups/ 所有冻结样例及来源记录，不能用新导出器重生成它们来通过测试。
3. 每个历史版本执行：解析/迁移 → 零库恢复 → 再导出；逐字段核对 ID、金额、业务/系统时间、历史、排序、标签、设置及重算结果。
4. 测试未来版本、冲突版本、坏校验和、缺表、错类型/引用、重复导入和事务失败不改原库。
5. 运行 scripts/check.ps1；涉及文件管道时补真实 Android SAF 往返。测试事实记录在阶段报告，不把本文当作测试结果。

参考样例：[当前最小样例](backup/finance-backup-v2.minimal.json)、[冻结样例来源](../test/fixtures/backups/README.md)。旧账本若并非此完整结构，应提供真实样本再编写明确迁移器，不能用“v0.0”掩盖无法识别的内容。
