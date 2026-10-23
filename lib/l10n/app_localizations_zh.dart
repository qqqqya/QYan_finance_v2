// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '财管';

  @override
  String get settings => '系统设置';

  @override
  String get totalAssets => '总资产';

  @override
  String get totalLiabilities => '总负债';

  @override
  String get netAssets => '净资产';

  @override
  String get myProjects => '我的项目';

  @override
  String get localOnly => '财务记录仅保存在此设备。';

  @override
  String get includedInAssets => '计入总资产';

  @override
  String get excludedFromAssets => '不计入总资产';

  @override
  String get liabilityBalance => '当前尚欠金额';

  @override
  String get independentIncome => '独立收入 · 累计';

  @override
  String get independentExpense => '独立支出 · 累计';

  @override
  String get appearanceAndLanguage => '外观与语言';

  @override
  String get themeMode => '主题模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get language => '语言';

  @override
  String get localData => '本地数据';

  @override
  String get currency => '币种';

  @override
  String get timeZone => '账本时区';

  @override
  String get saveError => '设置保存失败，请重试。';

  @override
  String get dataError => '本地数据读取失败，请重新打开应用重试。';

  @override
  String get startupError => '无法打开本地数据库，原有记录已保留。';

  @override
  String get retry => '重试';

  @override
  String projectName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'cmb': '招商银行',
      'bocom': '交通银行',
      'alipay': '支付宝',
      'cash': '现金',
      'fund': '基金',
      'investment': '理财产品',
      'liability': '负债',
      'largeIncome': '大额收入',
      'largeExpense': '大额支出',
      'other': '项目',
    });
    return '$_temp0';
  }

  @override
  String get newProject => '新建项目';

  @override
  String get editProject => '编辑项目';

  @override
  String get projectDetails => '项目详情';

  @override
  String get projectType => '项目类型';

  @override
  String get typeAsset => '资产';

  @override
  String get typeLiability => '负债';

  @override
  String get typeIncome => '独立收入';

  @override
  String get typeExpense => '独立支出';

  @override
  String get name => '名称';

  @override
  String get category => '分类';

  @override
  String get customCategory => '自定义分类（可选）';

  @override
  String get icon => '图标';

  @override
  String get color => '颜色';

  @override
  String get note => '备注';

  @override
  String get initialBalance => '初始余额';

  @override
  String get balanceAmount => '更新后的实际余额';

  @override
  String get entryAmount => '金额';

  @override
  String get businessDate => '业务日期 · YYYY-MM-DD';

  @override
  String get businessTime => '业务时间 · HH:mm';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get deleteProject => '删除项目';

  @override
  String get deleteProjectWarning => '删除此项目及其全部记录和修改历史？汇总与趋势将重新计算，此操作无法撤销。';

  @override
  String get deleteRecordWarning => '删除这条业务记录及其修改历史？金额统计将重新计算。';

  @override
  String get clearRecords => '清空全部记录';

  @override
  String get clearRecordsWarning => '删除该项目全部业务记录及相关修改历史？金额将归零，项目本身保留。';

  @override
  String get history => '修改历史';

  @override
  String get clearHistory => '清空修改历史';

  @override
  String get historyDeleteWarning => '清空此对象的修改历史？当前业务记录和金额保持不变。';

  @override
  String get deleteHistoryWarning => '删除这条修改历史？当前业务记录和金额保持不变。';

  @override
  String get historyEmpty => '暂无修改历史。';

  @override
  String get before => '修改前';

  @override
  String get after => '修改后';

  @override
  String get changedAt => '实际修改时间';

  @override
  String get createdAt => '创建时间';

  @override
  String get updatedAt => '最后修改时间';

  @override
  String get records => '业务记录';

  @override
  String get noRecords => '暂无记录，金额为零。';

  @override
  String get allMonths => '全部月份';

  @override
  String get selectMonth => '筛选月份 · YYYY-MM';

  @override
  String get updateBalance => '更新余额';

  @override
  String get addEntry => '记一笔';

  @override
  String get typeLocked => '已有记录，不能切换项目类型。';

  @override
  String get invalidName => '名称须为 1–80 个字符。';

  @override
  String get invalidAmount => '请输入最多两位小数的合法金额，上限 9,999,999,999.99；收支须大于零。';

  @override
  String get invalidDate => '请按标注格式填写有效日期和时间。';

  @override
  String get futureDate => '业务时间不能晚于账本时区的当前时间。';

  @override
  String get invalidText => '请检查分类及备注长度（备注最多 2,000 字）。';

  @override
  String get operationFailed => '操作未保存，请重试。';

  @override
  String get staleOrder => '排序时项目发生变化，请刷新后重试。';

  @override
  String get missingProject => '该项目或记录已不存在。';

  @override
  String get includeAsset => '计入总资产';

  @override
  String get includeLiability => '计入总负债';

  @override
  String get recordedChange => '相对上一余额的变化';

  @override
  String get assetComposition => '资产构成';

  @override
  String get liabilityComposition => '负债构成';

  @override
  String get assetTrend => '余额趋势';

  @override
  String get manualBasis => '基于当前项目的手动记录；按现有汇总开关回算。';

  @override
  String get emptyChart => '暂无正余额可展示。';

  @override
  String get noTrend => '此范围暂无余额记录。';

  @override
  String get days30 => '近 30 天';

  @override
  String get months12 => '近 12 个月';

  @override
  String get pointValues => '日期时间与余额';

  @override
  String get amountAxis => '金额 · 元';

  @override
  String get dateAxis => '业务日期';

  @override
  String get unsavedTitle => '尚未保存';

  @override
  String get unsavedBody => '离开前是否保存修改？';

  @override
  String get continueEditing => '继续编辑';

  @override
  String get discard => '放弃修改';

  @override
  String get sortHint => '按住独立把手排序；长按卡片打开操作菜单。';

  @override
  String get sortProjects => '项目排序';

  @override
  String get bankCategory => '银行账户';

  @override
  String get walletCategory => '电子钱包';

  @override
  String get otherCategory => '其他';

  @override
  String get colorNeutral => '中性';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorRed => '红色';

  @override
  String get monthlyBills => '月度账单';

  @override
  String get memos => '理财备忘录';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get surplus => '结余';

  @override
  String get billDetails => '账单明细';

  @override
  String get addBill => '记一笔';

  @override
  String get annualSummary => '年度汇总';

  @override
  String get year => '年份';

  @override
  String get month => '月份';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get chooseMonth => '选择年月';

  @override
  String get all => '全部';

  @override
  String get noBills => '当前范围没有账单。';

  @override
  String get billBasis => '账单与资产、独立收支项目完全独立。';

  @override
  String get billDistribution => '分类分布';

  @override
  String get savedMonth => '已记入月份：';

  @override
  String get viewMonth => '查看该月份';

  @override
  String get categories => '分类管理';

  @override
  String get newCategory => '新增分类';

  @override
  String get categoryInactive => '已停用';

  @override
  String get categoryActive => '可用于新账单';

  @override
  String get categoryFixed => '创建后分类方向固定。';

  @override
  String get categoryUnavailable => '请选择当前收支方向的有效分类。';

  @override
  String get categoryReferenced => '分类已被引用，请迁移账单后再删除。';

  @override
  String get categoryDeleteWarning => '删除此分类及其修改历史？';

  @override
  String get moveCategoryWarning => '将此分类的全部账单迁移到所选有效分类后删除？金额和日期不变，每笔迁移记录修改历史。';

  @override
  String get moveAndDelete => '迁移并删除';

  @override
  String get replacementCategory => '迁移至分类';

  @override
  String get chooseCategory => '请选择分类';

  @override
  String get deleteBillWarning => '删除此账单及其修改历史？月度和年度统计会更新，资产不变。';

  @override
  String get memoTitle => '标题';

  @override
  String get memoBody => '正文';

  @override
  String get tags => '标签';

  @override
  String get tagsHint => '用逗号分隔；最多 10 个标签，每个 30 字符。';

  @override
  String get newMemo => '新增备忘录';

  @override
  String get searchMemos => '搜索标题、正文或标签';

  @override
  String get noMemos => '当前范围没有备忘录。';

  @override
  String get deleteMemoWarning => '删除此备忘录及其修改历史？不影响任何金额。';

  @override
  String get memoTextError => '标题需 1–200 字符，正文最多 20,000 字符。';

  @override
  String get tagError => '最多 10 个标签，每个不超过 30 字符。';

  @override
  String get recordAxis => '记录顺序 · 业务日期';

  @override
  String get trendLineHint => '记录时点等距排列；直线仅示意变化，不代表时间间隔或记录之间的实际余额。';

  @override
  String get annualAxis => '月份 · 1–12';

  @override
  String get requiredField => '此项不能为空。';

  @override
  String get dataManagement => '数据管理';

  @override
  String get backupIntro => '管理本机的完整财务数据';

  @override
  String get currentData => '当前数据';

  @override
  String get localSaved => '本机保存';

  @override
  String get backupBills => '账单';

  @override
  String get backupAccounts => '资产 / 负债账户';

  @override
  String get backupProjects => '全部项目';

  @override
  String get lastBill => '最近记账';

  @override
  String get backupExport => '导出备份';

  @override
  String get backupExportHint => '将全部数据与设置保存为文件';

  @override
  String get backupImport => '导入恢复';

  @override
  String get backupImportHint => '从完整备份覆盖恢复全部数据';

  @override
  String get recentBackup => '最近备份';

  @override
  String get noBackup => '本次安装尚无成功导出记录。';

  @override
  String get backupSafety => '数据只保存在本机。换机或重装前请导出备份。备份为明文，包含完整财务数据，请妥善保存。';

  @override
  String get backupSuccess => '备份成功';

  @override
  String get backupSuccessBody => '完整备份已写入，并通过回读校验。';

  @override
  String get backupFileName => '文件名称';

  @override
  String get backupFileSize => '文件大小';

  @override
  String get backupLocation => '保存位置';

  @override
  String get shareBackup => '分享文件';

  @override
  String get done => '完成';

  @override
  String get backupPreview => '恢复预览';

  @override
  String get backupDate => '备份日期';

  @override
  String get backupReplaceWarning =>
      '将覆盖当前全部财务数据、修改历史和主题/语言设置。恢复前会保留一份当前数据的私有恢复副本。';

  @override
  String get confirmRestore => '确认覆盖恢复';

  @override
  String get restoreSuccess => '恢复完成';

  @override
  String get restoreSuccessBody => '全部记录和设置已恢复。';

  @override
  String get recoveryCopy => '导入前恢复副本';

  @override
  String get recoveryCopyHint => '只保留上次成功恢复之前的一份数据，不包含在导出文件中，卸载后不保留。';

  @override
  String get noRecoveryCopy => '暂无恢复副本。';

  @override
  String get restoreCopy => '预览并恢复副本';

  @override
  String get deleteCopy => '删除私有副本';

  @override
  String get deleteCopyWarning => '仅删除这份私有恢复副本？当前财务数据和外部备份文件不变。';

  @override
  String get factoryReset => '恢复出厂设置';

  @override
  String get factoryResetWarning =>
      '清除全部记录、修改历史及私有恢复副本，恢复默认零金额模板，主题和语言跟随系统。已经导出的外部文件会保留。';

  @override
  String get exportFirst => '先导出备份';

  @override
  String get confirmReset => '确认清空';

  @override
  String get resetSuccess => '已恢复出厂设置';

  @override
  String get resetSuccessBody => '默认项目金额全部归零，外部备份文件已保留。';

  @override
  String get backupError => '操作未完成';

  @override
  String get invalidBackup => '不是有效的 finance-backup v1 文件，或数据字段/关联无效。当前数据未被替换。';

  @override
  String get backupVersionError => '不支持此备份版本，数据未变更。';

  @override
  String get backupChecksumError => '备份完整性校验失败，数据未变更。';

  @override
  String get backupLimitError => '备份超过当前支持范围（32 MiB 或 100,000 条记录），未替换数据。';

  @override
  String get fileWriteError => '备份未能保存并校验，请检查剩余空间和保存位置。可能需要删除未完成的新文件。';

  @override
  String get fileReadError => '无法读取文件，请重新选择可访问的备份。数据未变更。';

  @override
  String get filePermissionError => '文件访问权限被拒绝或已失效，请重新选择文件。';

  @override
  String get noSpaceError => '存储空间不足，操作未完成。请释放空间后重试。';

  @override
  String get fileShareError => '无法打开系统分享面板，已保存的备份文件仍可使用。';

  @override
  String get restoreError => '恢复未完成，事务已保留原数据和原恢复副本。';

  @override
  String get recentRecordError => '文件已保存，但最近备份信息未能记录。';

  @override
  String get cachePurgeError => '数据已重置，但私有分享缓存待清理。请在此重试，下次启动也会继续清理。';

  @override
  String get purgeCache => '重试清理私有缓存';

  @override
  String get backupCancelled => '已取消，财务数据未变更。';

  @override
  String get backupFormat => '备份格式';

  @override
  String get backupFutureVersionError => '此备份使用更新的格式，请先升级本应用再恢复。当前数据未更改。';

  @override
  String get legacyBackupWarning =>
      '此旧备份没有校验和，无法验证文件原始完整性；结构和业务数据已通过检查，请核对预览后再确认覆盖。';

  @override
  String get loadMore => '再加载 50 条';

  @override
  String get backupFilePrefix => '财务备份';

  @override
  String get backupCountsHint => '包含余额、独立收支、分类、备忘录、修改历史与设置。';

  @override
  String billCategoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'salary': '工资',
      'bonus': '奖金',
      'otherIncome': '其他收入',
      'food': '餐饮',
      'transport': '交通',
      'shopping': '购物',
      'housing': '住房',
      'medical': '医疗',
      'otherExpense': '其他支出',
      'other': '分类',
    });
    return '$_temp0';
  }

  @override
  String get themeColor => '主题配色';

  @override
  String get themeRed => '火红色';

  @override
  String get themeGreen => '绿色';

  @override
  String get themePurple => '紫色';

  @override
  String get themeBlue => '蓝色';

  @override
  String get projectActions => '项目操作';

  @override
  String get dragProject => '按住把手拖动排序';

  @override
  String deleteProjectImpact(int records, int histories) {
    return '将删除 $records 条业务记录和 $histories 条修改历史。月度账单及其他项目不受影响。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appName => '财管';

  @override
  String get settings => '系统设置';

  @override
  String get totalAssets => '总资产';

  @override
  String get totalLiabilities => '总负债';

  @override
  String get netAssets => '净资产';

  @override
  String get myProjects => '我的项目';

  @override
  String get localOnly => '财务记录仅保存在此设备。';

  @override
  String get includedInAssets => '计入总资产';

  @override
  String get excludedFromAssets => '不计入总资产';

  @override
  String get liabilityBalance => '当前尚欠金额';

  @override
  String get independentIncome => '独立收入 · 累计';

  @override
  String get independentExpense => '独立支出 · 累计';

  @override
  String get appearanceAndLanguage => '外观与语言';

  @override
  String get themeMode => '主题模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get language => '语言';

  @override
  String get localData => '本地数据';

  @override
  String get currency => '币种';

  @override
  String get timeZone => '账本时区';

  @override
  String get saveError => '设置保存失败，请重试。';

  @override
  String get dataError => '本地数据读取失败，请重新打开应用重试。';

  @override
  String get startupError => '无法打开本地数据库，原有记录已保留。';

  @override
  String get retry => '重试';

  @override
  String projectName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'cmb': '招商银行',
      'bocom': '交通银行',
      'alipay': '支付宝',
      'cash': '现金',
      'fund': '基金',
      'investment': '理财产品',
      'liability': '负债',
      'largeIncome': '大额收入',
      'largeExpense': '大额支出',
      'other': '项目',
    });
    return '$_temp0';
  }

  @override
  String get newProject => '新建项目';

  @override
  String get editProject => '编辑项目';

  @override
  String get projectDetails => '项目详情';

  @override
  String get projectType => '项目类型';

  @override
  String get typeAsset => '资产';

  @override
  String get typeLiability => '负债';

  @override
  String get typeIncome => '独立收入';

  @override
  String get typeExpense => '独立支出';

  @override
  String get name => '名称';

  @override
  String get category => '分类';

  @override
  String get customCategory => '自定义分类（可选）';

  @override
  String get icon => '图标';

  @override
  String get color => '颜色';

  @override
  String get note => '备注';

  @override
  String get initialBalance => '初始余额';

  @override
  String get balanceAmount => '更新后的实际余额';

  @override
  String get entryAmount => '金额';

  @override
  String get businessDate => '业务日期 · YYYY-MM-DD';

  @override
  String get businessTime => '业务时间 · HH:mm';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get deleteProject => '删除项目';

  @override
  String get deleteProjectWarning => '删除此项目及其全部记录和修改历史？汇总与趋势将重新计算，此操作无法撤销。';

  @override
  String get deleteRecordWarning => '删除这条业务记录及其修改历史？金额统计将重新计算。';

  @override
  String get clearRecords => '清空全部记录';

  @override
  String get clearRecordsWarning => '删除该项目全部业务记录及相关修改历史？金额将归零，项目本身保留。';

  @override
  String get history => '修改历史';

  @override
  String get clearHistory => '清空修改历史';

  @override
  String get historyDeleteWarning => '清空此对象的修改历史？当前业务记录和金额保持不变。';

  @override
  String get deleteHistoryWarning => '删除这条修改历史？当前业务记录和金额保持不变。';

  @override
  String get historyEmpty => '暂无修改历史。';

  @override
  String get before => '修改前';

  @override
  String get after => '修改后';

  @override
  String get changedAt => '实际修改时间';

  @override
  String get createdAt => '创建时间';

  @override
  String get updatedAt => '最后修改时间';

  @override
  String get records => '业务记录';

  @override
  String get noRecords => '暂无记录，金额为零。';

  @override
  String get allMonths => '全部月份';

  @override
  String get selectMonth => '筛选月份 · YYYY-MM';

  @override
  String get updateBalance => '更新余额';

  @override
  String get addEntry => '记一笔';

  @override
  String get typeLocked => '已有记录，不能切换项目类型。';

  @override
  String get invalidName => '名称须为 1–80 个字符。';

  @override
  String get invalidAmount => '请输入最多两位小数的合法金额，上限 9,999,999,999.99；收支须大于零。';

  @override
  String get invalidDate => '请按标注格式填写有效日期和时间。';

  @override
  String get futureDate => '业务时间不能晚于账本时区的当前时间。';

  @override
  String get invalidText => '请检查分类及备注长度（备注最多 2,000 字）。';

  @override
  String get operationFailed => '操作未保存，请重试。';

  @override
  String get staleOrder => '排序时项目发生变化，请刷新后重试。';

  @override
  String get missingProject => '该项目或记录已不存在。';

  @override
  String get includeAsset => '计入总资产';

  @override
  String get includeLiability => '计入总负债';

  @override
  String get recordedChange => '相对上一余额的变化';

  @override
  String get assetComposition => '资产构成';

  @override
  String get liabilityComposition => '负债构成';

  @override
  String get assetTrend => '余额趋势';

  @override
  String get manualBasis => '基于当前项目的手动记录；按现有汇总开关回算。';

  @override
  String get emptyChart => '暂无正余额可展示。';

  @override
  String get noTrend => '此范围暂无余额记录。';

  @override
  String get days30 => '近 30 天';

  @override
  String get months12 => '近 12 个月';

  @override
  String get pointValues => '日期时间与余额';

  @override
  String get amountAxis => '金额 · 元';

  @override
  String get dateAxis => '业务日期';

  @override
  String get unsavedTitle => '尚未保存';

  @override
  String get unsavedBody => '离开前是否保存修改？';

  @override
  String get continueEditing => '继续编辑';

  @override
  String get discard => '放弃修改';

  @override
  String get sortHint => '按住独立把手排序；长按卡片打开操作菜单。';

  @override
  String get sortProjects => '项目排序';

  @override
  String get bankCategory => '银行账户';

  @override
  String get walletCategory => '电子钱包';

  @override
  String get otherCategory => '其他';

  @override
  String get colorNeutral => '中性';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorRed => '红色';

  @override
  String get monthlyBills => '月度账单';

  @override
  String get memos => '理财备忘录';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get surplus => '结余';

  @override
  String get billDetails => '账单明细';

  @override
  String get addBill => '记一笔';

  @override
  String get annualSummary => '年度汇总';

  @override
  String get year => '年份';

  @override
  String get month => '月份';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get chooseMonth => '选择年月';

  @override
  String get all => '全部';

  @override
  String get noBills => '当前范围没有账单。';

  @override
  String get billBasis => '账单与资产、独立收支项目完全独立。';

  @override
  String get billDistribution => '分类分布';

  @override
  String get savedMonth => '已记入月份：';

  @override
  String get viewMonth => '查看该月份';

  @override
  String get categories => '分类管理';

  @override
  String get newCategory => '新增分类';

  @override
  String get categoryInactive => '已停用';

  @override
  String get categoryActive => '可用于新账单';

  @override
  String get categoryFixed => '创建后分类方向固定。';

  @override
  String get categoryUnavailable => '请选择当前收支方向的有效分类。';

  @override
  String get categoryReferenced => '分类已被引用，请迁移账单后再删除。';

  @override
  String get categoryDeleteWarning => '删除此分类及其修改历史？';

  @override
  String get moveCategoryWarning => '将此分类的全部账单迁移到所选有效分类后删除？金额和日期不变，每笔迁移记录修改历史。';

  @override
  String get moveAndDelete => '迁移并删除';

  @override
  String get replacementCategory => '迁移至分类';

  @override
  String get chooseCategory => '请选择分类';

  @override
  String get deleteBillWarning => '删除此账单及其修改历史？月度和年度统计会更新，资产不变。';

  @override
  String get memoTitle => '标题';

  @override
  String get memoBody => '正文';

  @override
  String get tags => '标签';

  @override
  String get tagsHint => '用逗号分隔；最多 10 个标签，每个 30 字符。';

  @override
  String get newMemo => '新增备忘录';

  @override
  String get searchMemos => '搜索标题、正文或标签';

  @override
  String get noMemos => '当前范围没有备忘录。';

  @override
  String get deleteMemoWarning => '删除此备忘录及其修改历史？不影响任何金额。';

  @override
  String get memoTextError => '标题需 1–200 字符，正文最多 20,000 字符。';

  @override
  String get tagError => '最多 10 个标签，每个不超过 30 字符。';

  @override
  String get recordAxis => '记录顺序 · 业务日期';

  @override
  String get trendLineHint => '记录时点等距排列；直线仅示意变化，不代表时间间隔或记录之间的实际余额。';

  @override
  String get annualAxis => '月份 · 1–12';

  @override
  String get requiredField => '此项不能为空。';

  @override
  String get dataManagement => '数据管理';

  @override
  String get backupIntro => '管理本机的完整财务数据';

  @override
  String get currentData => '当前数据';

  @override
  String get localSaved => '本机保存';

  @override
  String get backupBills => '账单';

  @override
  String get backupAccounts => '资产 / 负债账户';

  @override
  String get backupProjects => '全部项目';

  @override
  String get lastBill => '最近记账';

  @override
  String get backupExport => '导出备份';

  @override
  String get backupExportHint => '将全部数据与设置保存为文件';

  @override
  String get backupImport => '导入恢复';

  @override
  String get backupImportHint => '从完整备份覆盖恢复全部数据';

  @override
  String get recentBackup => '最近备份';

  @override
  String get noBackup => '本次安装尚无成功导出记录。';

  @override
  String get backupSafety => '数据只保存在本机。换机或重装前请导出备份。备份为明文，包含完整财务数据，请妥善保存。';

  @override
  String get backupSuccess => '备份成功';

  @override
  String get backupSuccessBody => '完整备份已写入，并通过回读校验。';

  @override
  String get backupFileName => '文件名称';

  @override
  String get backupFileSize => '文件大小';

  @override
  String get backupLocation => '保存位置';

  @override
  String get shareBackup => '分享文件';

  @override
  String get done => '完成';

  @override
  String get backupPreview => '恢复预览';

  @override
  String get backupDate => '备份日期';

  @override
  String get backupReplaceWarning =>
      '将覆盖当前全部财务数据、修改历史和主题/语言设置。恢复前会保留一份当前数据的私有恢复副本。';

  @override
  String get confirmRestore => '确认覆盖恢复';

  @override
  String get restoreSuccess => '恢复完成';

  @override
  String get restoreSuccessBody => '全部记录和设置已恢复。';

  @override
  String get recoveryCopy => '导入前恢复副本';

  @override
  String get recoveryCopyHint => '只保留上次成功恢复之前的一份数据，不包含在导出文件中，卸载后不保留。';

  @override
  String get noRecoveryCopy => '暂无恢复副本。';

  @override
  String get restoreCopy => '预览并恢复副本';

  @override
  String get deleteCopy => '删除私有副本';

  @override
  String get deleteCopyWarning => '仅删除这份私有恢复副本？当前财务数据和外部备份文件不变。';

  @override
  String get factoryReset => '恢复出厂设置';

  @override
  String get factoryResetWarning =>
      '清除全部记录、修改历史及私有恢复副本，恢复默认零金额模板，主题和语言跟随系统。已经导出的外部文件会保留。';

  @override
  String get exportFirst => '先导出备份';

  @override
  String get confirmReset => '确认清空';

  @override
  String get resetSuccess => '已恢复出厂设置';

  @override
  String get resetSuccessBody => '默认项目金额全部归零，外部备份文件已保留。';

  @override
  String get backupError => '操作未完成';

  @override
  String get invalidBackup => '不是有效的 finance-backup v1 文件，或数据字段/关联无效。当前数据未被替换。';

  @override
  String get backupVersionError => '不支持此备份版本，数据未变更。';

  @override
  String get backupChecksumError => '备份完整性校验失败，数据未变更。';

  @override
  String get backupLimitError => '备份超过当前支持范围（32 MiB 或 100,000 条记录），未替换数据。';

  @override
  String get fileWriteError => '备份未能保存并校验，请检查剩余空间和保存位置。可能需要删除未完成的新文件。';

  @override
  String get fileReadError => '无法读取文件，请重新选择可访问的备份。数据未变更。';

  @override
  String get filePermissionError => '文件访问权限被拒绝或已失效，请重新选择文件。';

  @override
  String get noSpaceError => '存储空间不足，操作未完成。请释放空间后重试。';

  @override
  String get fileShareError => '无法打开系统分享面板，已保存的备份文件仍可使用。';

  @override
  String get restoreError => '恢复未完成，事务已保留原数据和原恢复副本。';

  @override
  String get recentRecordError => '文件已保存，但最近备份信息未能记录。';

  @override
  String get cachePurgeError => '数据已重置，但私有分享缓存待清理。请在此重试，下次启动也会继续清理。';

  @override
  String get purgeCache => '重试清理私有缓存';

  @override
  String get backupCancelled => '已取消，财务数据未变更。';

  @override
  String get backupFormat => '备份格式';

  @override
  String get backupFutureVersionError => '此备份使用更新的格式，请先升级本应用再恢复。当前数据未更改。';

  @override
  String get legacyBackupWarning =>
      '此旧备份没有校验和，无法验证文件原始完整性；结构和业务数据已通过检查，请核对预览后再确认覆盖。';

  @override
  String get loadMore => '再加载 50 条';

  @override
  String get backupFilePrefix => '财务备份';

  @override
  String get backupCountsHint => '包含余额、独立收支、分类、备忘录、修改历史与设置。';

  @override
  String billCategoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'salary': '工资',
      'bonus': '奖金',
      'otherIncome': '其他收入',
      'food': '餐饮',
      'transport': '交通',
      'shopping': '购物',
      'housing': '住房',
      'medical': '医疗',
      'otherExpense': '其他支出',
      'other': '分类',
    });
    return '$_temp0';
  }

  @override
  String get themeColor => '主题配色';

  @override
  String get themeRed => '火红色';

  @override
  String get themeGreen => '绿色';

  @override
  String get themePurple => '紫色';

  @override
  String get themeBlue => '蓝色';

  @override
  String get projectActions => '项目操作';

  @override
  String get dragProject => '按住把手拖动排序';

  @override
  String deleteProjectImpact(int records, int histories) {
    return '将删除 $records 条业务记录和 $histories 条修改历史。月度账单及其他项目不受影响。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => '財管';

  @override
  String get settings => '系統設定';

  @override
  String get totalAssets => '總資產';

  @override
  String get totalLiabilities => '總負債';

  @override
  String get netAssets => '淨資產';

  @override
  String get myProjects => '我的項目';

  @override
  String get localOnly => '財務記錄僅儲存在此裝置。';

  @override
  String get includedInAssets => '計入總資產';

  @override
  String get excludedFromAssets => '不計入總資產';

  @override
  String get liabilityBalance => '目前尚欠金額';

  @override
  String get independentIncome => '獨立收入 · 累計';

  @override
  String get independentExpense => '獨立支出 · 累計';

  @override
  String get appearanceAndLanguage => '外觀與語言';

  @override
  String get themeMode => '主題模式';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get language => '語言';

  @override
  String get localData => '本機資料';

  @override
  String get currency => '幣別';

  @override
  String get timeZone => '帳本時區';

  @override
  String get saveError => '設定儲存失敗，請重試。';

  @override
  String get dataError => '本機資料讀取失敗，請重新開啟應用程式重試。';

  @override
  String get startupError => '無法開啟本機資料庫，原有記錄已保留。';

  @override
  String get retry => '重試';

  @override
  String projectName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'cmb': '招商銀行',
      'bocom': '交通銀行',
      'alipay': '支付寶',
      'cash': '現金',
      'fund': '基金',
      'investment': '理財產品',
      'liability': '負債',
      'largeIncome': '大額收入',
      'largeExpense': '大額支出',
      'other': '項目',
    });
    return '$_temp0';
  }

  @override
  String get newProject => '新增項目';

  @override
  String get editProject => '編輯項目';

  @override
  String get projectDetails => '項目詳情';

  @override
  String get projectType => '項目類型';

  @override
  String get typeAsset => '資產';

  @override
  String get typeLiability => '負債';

  @override
  String get typeIncome => '獨立收入';

  @override
  String get typeExpense => '獨立支出';

  @override
  String get name => '名稱';

  @override
  String get category => '分類';

  @override
  String get customCategory => '自訂分類（選填）';

  @override
  String get icon => '圖示';

  @override
  String get color => '顏色';

  @override
  String get note => '備註';

  @override
  String get initialBalance => '初始餘額';

  @override
  String get balanceAmount => '更新後的實際餘額';

  @override
  String get entryAmount => '金額';

  @override
  String get businessDate => '業務日期 · YYYY-MM-DD';

  @override
  String get businessTime => '業務時間 · HH:mm';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get edit => '編輯';

  @override
  String get deleteProject => '刪除項目';

  @override
  String get deleteProjectWarning => '刪除此項目及其全部記錄和修改歷史？彙總與趨勢將重新計算，此操作無法復原。';

  @override
  String get deleteRecordWarning => '刪除此業務記錄及其修改歷史？金額統計將重新計算。';

  @override
  String get clearRecords => '清空全部記錄';

  @override
  String get clearRecordsWarning => '刪除此項目全部業務記錄及相關修改歷史？金額將歸零，項目本身保留。';

  @override
  String get history => '修改歷史';

  @override
  String get clearHistory => '清空修改歷史';

  @override
  String get historyDeleteWarning => '清除此物件的修改歷史？目前業務記錄和金額維持不變。';

  @override
  String get deleteHistoryWarning => '刪除此修改歷史？目前業務記錄和金額維持不變。';

  @override
  String get historyEmpty => '尚無修改歷史。';

  @override
  String get before => '修改前';

  @override
  String get after => '修改後';

  @override
  String get changedAt => '實際修改時間';

  @override
  String get createdAt => '建立時間';

  @override
  String get updatedAt => '最後修改時間';

  @override
  String get records => '業務記錄';

  @override
  String get noRecords => '尚無記錄，金額為零。';

  @override
  String get allMonths => '全部月份';

  @override
  String get selectMonth => '篩選月份 · YYYY-MM';

  @override
  String get updateBalance => '更新餘額';

  @override
  String get addEntry => '新增一筆';

  @override
  String get typeLocked => '已有記錄，無法切換項目類型。';

  @override
  String get invalidName => '名稱須為 1–80 個字元。';

  @override
  String get invalidAmount => '請輸入最多兩位小數的合法金額，上限 9,999,999,999.99；收支須大於零。';

  @override
  String get invalidDate => '請依標示格式輸入有效日期與時間。';

  @override
  String get futureDate => '業務時間不能晚於帳本時區的目前時間。';

  @override
  String get invalidText => '請檢查分類及備註長度（備註最多 2,000 字）。';

  @override
  String get operationFailed => '操作未儲存，請重試。';

  @override
  String get staleOrder => '排序時項目發生變更，請重新整理後重試。';

  @override
  String get missingProject => '此項目或記錄已不存在。';

  @override
  String get includeAsset => '計入總資產';

  @override
  String get includeLiability => '計入總負債';

  @override
  String get recordedChange => '相對上一餘額的變化';

  @override
  String get assetComposition => '資產組成';

  @override
  String get liabilityComposition => '負債組成';

  @override
  String get assetTrend => '餘額趨勢';

  @override
  String get manualBasis => '依目前項目的手動記錄；按現有彙總開關回算。';

  @override
  String get emptyChart => '尚無正餘額可顯示。';

  @override
  String get noTrend => '此範圍尚無餘額記錄。';

  @override
  String get days30 => '近 30 天';

  @override
  String get months12 => '近 12 個月';

  @override
  String get pointValues => '日期時間與餘額';

  @override
  String get amountAxis => '金額 · 元';

  @override
  String get dateAxis => '業務日期';

  @override
  String get unsavedTitle => '尚未儲存';

  @override
  String get unsavedBody => '離開前是否儲存修改？';

  @override
  String get continueEditing => '繼續編輯';

  @override
  String get discard => '放棄修改';

  @override
  String get sortHint => '按住獨立把手排序；長按卡片開啟操作選單。';

  @override
  String get sortProjects => '項目排序';

  @override
  String get bankCategory => '銀行帳戶';

  @override
  String get walletCategory => '電子錢包';

  @override
  String get otherCategory => '其他';

  @override
  String get colorNeutral => '中性';

  @override
  String get colorBlue => '藍色';

  @override
  String get colorGreen => '綠色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorRed => '紅色';

  @override
  String get monthlyBills => '月度帳單';

  @override
  String get memos => '理財備忘錄';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get surplus => '結餘';

  @override
  String get billDetails => '帳單明細';

  @override
  String get addBill => '記一筆';

  @override
  String get annualSummary => '年度彙總';

  @override
  String get year => '年份';

  @override
  String get month => '月份';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get chooseMonth => '選擇年月';

  @override
  String get all => '全部';

  @override
  String get noBills => '目前範圍沒有帳單。';

  @override
  String get billBasis => '帳單與資產、獨立收支項目完全獨立。';

  @override
  String get billDistribution => '分類分佈';

  @override
  String get savedMonth => '已記入月份：';

  @override
  String get viewMonth => '查看該月份';

  @override
  String get categories => '分類管理';

  @override
  String get newCategory => '新增分類';

  @override
  String get categoryInactive => '已停用';

  @override
  String get categoryActive => '可用於新帳單';

  @override
  String get categoryFixed => '建立後分類方向固定。';

  @override
  String get categoryUnavailable => '請選擇目前收支方向的有效分類。';

  @override
  String get categoryReferenced => '分類已被引用，請遷移帳單後再刪除。';

  @override
  String get categoryDeleteWarning => '刪除此分類及其修改歷史？';

  @override
  String get moveCategoryWarning => '將此分類的全部帳單遷移到所選有效分類後刪除？金額和日期不變，每筆遷移記錄修改歷史。';

  @override
  String get moveAndDelete => '遷移並刪除';

  @override
  String get replacementCategory => '遷移至分類';

  @override
  String get chooseCategory => '請選擇分類';

  @override
  String get deleteBillWarning => '刪除此帳單及其修改歷史？月度和年度統計會更新，資產不變。';

  @override
  String get memoTitle => '標題';

  @override
  String get memoBody => '正文';

  @override
  String get tags => '標籤';

  @override
  String get tagsHint => '用逗號分隔；最多 10 個標籤，每個 30 字元。';

  @override
  String get newMemo => '新增備忘錄';

  @override
  String get searchMemos => '搜尋標題、正文或標籤';

  @override
  String get noMemos => '目前範圍沒有備忘錄。';

  @override
  String get deleteMemoWarning => '刪除此備忘錄及其修改歷史？不影響任何金額。';

  @override
  String get memoTextError => '標題需 1–200 字元，正文最多 20,000 字元。';

  @override
  String get tagError => '最多 10 個標籤，每個不超過 30 字元。';

  @override
  String get recordAxis => '記錄順序 · 業務日期';

  @override
  String get trendLineHint => '記錄時點等距排列；直線僅示意變化，不代表時間間隔或記錄之間的實際餘額。';

  @override
  String get annualAxis => '月份 · 1–12';

  @override
  String get requiredField => '此項不能為空。';

  @override
  String get dataManagement => '資料管理';

  @override
  String get backupIntro => '管理本機的完整財務資料';

  @override
  String get currentData => '目前資料';

  @override
  String get localSaved => '本機儲存';

  @override
  String get backupBills => '帳單';

  @override
  String get backupAccounts => '資產 / 負債帳戶';

  @override
  String get backupProjects => '全部項目';

  @override
  String get lastBill => '最近記帳';

  @override
  String get backupExport => '匯出備份';

  @override
  String get backupExportHint => '將全部資料與設定儲存為檔案';

  @override
  String get backupImport => '匯入還原';

  @override
  String get backupImportHint => '從完整備份覆蓋還原全部資料';

  @override
  String get recentBackup => '最近備份';

  @override
  String get noBackup => '本次安裝尚無成功匯出記錄。';

  @override
  String get backupSafety => '資料只儲存在本機。換機或重新安裝前請匯出備份。備份為明文，包含完整財務資料，請妥善保存。';

  @override
  String get backupSuccess => '備份成功';

  @override
  String get backupSuccessBody => '完整備份已寫入，並通過回讀校驗。';

  @override
  String get backupFileName => '檔案名稱';

  @override
  String get backupFileSize => '檔案大小';

  @override
  String get backupLocation => '儲存位置';

  @override
  String get shareBackup => '分享檔案';

  @override
  String get done => '完成';

  @override
  String get backupPreview => '還原預覽';

  @override
  String get backupDate => '備份日期';

  @override
  String get backupReplaceWarning =>
      '將覆蓋目前全部財務資料、修改歷史和主題/語言設定。還原前會保留一份目前資料的私有還原副本。';

  @override
  String get confirmRestore => '確認覆蓋還原';

  @override
  String get restoreSuccess => '還原完成';

  @override
  String get restoreSuccessBody => '全部記錄和設定已還原。';

  @override
  String get recoveryCopy => '匯入前還原副本';

  @override
  String get recoveryCopyHint => '只保留上次成功還原之前的一份資料，不包含在匯出檔案中，解除安裝後不保留。';

  @override
  String get noRecoveryCopy => '暫無還原副本。';

  @override
  String get restoreCopy => '預覽並還原副本';

  @override
  String get deleteCopy => '刪除私有副本';

  @override
  String get deleteCopyWarning => '僅刪除這份私有還原副本？目前財務資料和外部備份檔案不變。';

  @override
  String get factoryReset => '恢復原廠設定';

  @override
  String get factoryResetWarning =>
      '清除全部記錄、修改歷史及私有還原副本，恢復預設零金額範本，主題和語言跟隨系統。已匯出的外部檔案會保留。';

  @override
  String get exportFirst => '先匯出備份';

  @override
  String get confirmReset => '確認清空';

  @override
  String get resetSuccess => '已恢復原廠設定';

  @override
  String get resetSuccessBody => '預設項目金額全部歸零，外部備份檔案已保留。';

  @override
  String get backupError => '操作未完成';

  @override
  String get invalidBackup => '不是有效的 finance-backup v1 檔案，或資料欄位/關聯無效。目前資料未被替換。';

  @override
  String get backupVersionError => '不支援此備份版本，資料未變更。';

  @override
  String get backupChecksumError => '備份完整性校驗失敗，資料未變更。';

  @override
  String get backupLimitError => '備份超過目前支援範圍（32 MiB 或 100,000 筆記錄），未替換資料。';

  @override
  String get fileWriteError => '備份未能儲存並校驗，請檢查剩餘空間和儲存位置。可能需要刪除未完成的新檔案。';

  @override
  String get fileReadError => '無法讀取檔案，請重新選擇可存取的備份。資料未變更。';

  @override
  String get filePermissionError => '檔案存取權限被拒絕或已失效，請重新選擇檔案。';

  @override
  String get noSpaceError => '儲存空間不足，操作未完成。請釋放空間後重試。';

  @override
  String get fileShareError => '無法開啟系統分享面板，已儲存的備份檔案仍可使用。';

  @override
  String get restoreError => '還原未完成，交易已保留原資料和原還原副本。';

  @override
  String get recentRecordError => '檔案已儲存，但最近備份資訊未能記錄。';

  @override
  String get cachePurgeError => '資料已重設，但私有分享快取待清理。請在此重試，下次啟動也會繼續清理。';

  @override
  String get purgeCache => '重試清理私有快取';

  @override
  String get backupCancelled => '已取消，財務資料未變更。';

  @override
  String get backupFormat => '備份格式';

  @override
  String get backupFutureVersionError => '此備份使用更新的格式，請先升級本應用程式再還原。目前資料未變更。';

  @override
  String get legacyBackupWarning =>
      '此舊備份沒有校驗和，無法驗證檔案原始完整性；結構和業務資料已通過檢查，請核對預覽後再確認覆蓋。';

  @override
  String get loadMore => '再載入 50 筆';

  @override
  String get backupFilePrefix => '財務備份';

  @override
  String get backupCountsHint => '包含餘額、獨立收支、分類、備忘錄、修改歷史與設定。';

  @override
  String billCategoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'salary': '薪資',
      'bonus': '獎金',
      'otherIncome': '其他收入',
      'food': '餐飲',
      'transport': '交通',
      'shopping': '購物',
      'housing': '住房',
      'medical': '醫療',
      'otherExpense': '其他支出',
      'other': '分類',
    });
    return '$_temp0';
  }

  @override
  String get themeColor => '主題配色';

  @override
  String get themeRed => '火紅色';

  @override
  String get themeGreen => '綠色';

  @override
  String get themePurple => '紫色';

  @override
  String get themeBlue => '藍色';

  @override
  String get projectActions => '項目操作';

  @override
  String get dragProject => '按住把手拖曳排序';

  @override
  String deleteProjectImpact(int records, int histories) {
    return '將刪除 $records 筆業務記錄和 $histories 筆修改歷史。月度帳單及其他項目不受影響。';
  }
}
