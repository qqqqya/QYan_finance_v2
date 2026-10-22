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
  String get sortHint => '长按拖动卡片可排序。';

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
  String get sortHint => '长按拖动卡片可排序。';

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
  String get sortHint => '長按拖曳卡片可排序。';

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
}
