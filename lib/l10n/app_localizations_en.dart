// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Finances';

  @override
  String get settings => 'Settings';

  @override
  String get totalAssets => 'Total assets';

  @override
  String get totalLiabilities => 'Total liabilities';

  @override
  String get netAssets => 'Net assets';

  @override
  String get myProjects => 'My projects';

  @override
  String get localOnly => 'Your records are stored only on this device.';

  @override
  String get includedInAssets => 'Included in total assets';

  @override
  String get excludedFromAssets => 'Excluded from total assets';

  @override
  String get liabilityBalance => 'Outstanding balance';

  @override
  String get independentIncome => 'Independent income · cumulative';

  @override
  String get independentExpense => 'Independent expense · cumulative';

  @override
  String get appearanceAndLanguage => 'Appearance & language';

  @override
  String get themeMode => 'Theme';

  @override
  String get followSystem => 'Follow system';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get localData => 'Local data';

  @override
  String get currency => 'Currency';

  @override
  String get timeZone => 'Book time zone';

  @override
  String get saveError => 'Your setting could not be saved. Please try again.';

  @override
  String get dataError =>
      'Your local data could not be read. Please reopen the app to retry.';

  @override
  String get startupError =>
      'The app could not open its local database. Your existing records have been kept.';

  @override
  String get retry => 'Retry';

  @override
  String projectName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'cmb': 'China Merchants Bank',
      'bocom': 'Bank of Communications',
      'alipay': 'Alipay',
      'cash': 'Cash',
      'fund': 'Funds',
      'investment': 'Investments',
      'liability': 'Liabilities',
      'largeIncome': 'Large income',
      'largeExpense': 'Large expenses',
      'other': 'Project',
    });
    return '$_temp0';
  }

  @override
  String get newProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get projectDetails => 'Project details';

  @override
  String get projectType => 'Project type';

  @override
  String get typeAsset => 'Asset';

  @override
  String get typeLiability => 'Liability';

  @override
  String get typeIncome => 'Independent income';

  @override
  String get typeExpense => 'Independent expense';

  @override
  String get name => 'Name';

  @override
  String get category => 'Category';

  @override
  String get customCategory => 'Custom category (optional)';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get note => 'Note';

  @override
  String get initialBalance => 'Initial balance';

  @override
  String get balanceAmount => 'Actual balance after update';

  @override
  String get entryAmount => 'Amount';

  @override
  String get businessDate => 'Business date · YYYY-MM-DD';

  @override
  String get businessTime => 'Business time · HH:mm';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get deleteProjectWarning =>
      'Delete this project, all its records and edit history? Totals and trends will be recalculated. This cannot be undone.';

  @override
  String get deleteRecordWarning =>
      'Delete this record and its edit history? Its amount will be removed from calculations.';

  @override
  String get clearRecords => 'Clear all records';

  @override
  String get clearRecordsWarning =>
      'Delete all records and their edit history in this project? Its amount will become zero. The project itself stays.';

  @override
  String get history => 'Edit history';

  @override
  String get clearHistory => 'Clear edit history';

  @override
  String get historyDeleteWarning =>
      'Clear this object\'s edit history? Current records and amounts will remain unchanged.';

  @override
  String get deleteHistoryWarning =>
      'Delete this edit history item? The current record and amount will stay unchanged.';

  @override
  String get historyEmpty => 'No edits recorded.';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get changedAt => 'Edited at';

  @override
  String get createdAt => 'Created at';

  @override
  String get updatedAt => 'Last edited';

  @override
  String get records => 'Records';

  @override
  String get noRecords => 'No records yet. Amount is zero.';

  @override
  String get allMonths => 'All months';

  @override
  String get selectMonth => 'Filter month · YYYY-MM';

  @override
  String get updateBalance => 'Update balance';

  @override
  String get addEntry => 'Add entry';

  @override
  String get typeLocked => 'Projects with records cannot change type.';

  @override
  String get invalidName => 'Enter a name of 1–80 characters.';

  @override
  String get invalidAmount =>
      'Use a valid amount with at most 2 decimals, up to 9,999,999,999.99. Entries must be greater than zero.';

  @override
  String get invalidDate =>
      'Use a valid date and time in the displayed format.';

  @override
  String get futureDate =>
      'Business time cannot be in the future of the book time zone.';

  @override
  String get invalidText =>
      'Check category and note length (note: max 2,000 characters).';

  @override
  String get operationFailed => 'The change was not saved. Please try again.';

  @override
  String get staleOrder =>
      'Projects changed while sorting. Reload and try again.';

  @override
  String get missingProject => 'This project or record no longer exists.';

  @override
  String get includeAsset => 'Include in total assets';

  @override
  String get includeLiability => 'Include in total liabilities';

  @override
  String get recordedChange => 'Change from previous balance';

  @override
  String get assetComposition => 'Asset composition';

  @override
  String get liabilityComposition => 'Liabilities';

  @override
  String get assetTrend => 'Balance trend';

  @override
  String get manualBasis =>
      'Based on manual records of currently included projects.';

  @override
  String get emptyChart => 'No positive balances to display.';

  @override
  String get noTrend => 'No balance records in this period.';

  @override
  String get days30 => '30 days';

  @override
  String get months12 => '12 months';

  @override
  String get pointValues => 'Date / time and balance';

  @override
  String get amountAxis => 'Amount · CNY';

  @override
  String get dateAxis => 'Business date';

  @override
  String get unsavedTitle => 'Unsaved changes';

  @override
  String get unsavedBody => 'Save your changes before leaving?';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get sortHint => 'Long press and drag cards to reorder.';

  @override
  String get sortProjects => 'Reorder projects';

  @override
  String get bankCategory => 'Bank account';

  @override
  String get walletCategory => 'Wallet';

  @override
  String get otherCategory => 'Other';

  @override
  String get colorNeutral => 'Neutral';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorRed => 'Red';

  @override
  String get monthlyBills => 'Monthly bills';

  @override
  String get memos => 'Finance memos';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get surplus => 'Surplus';

  @override
  String get billDetails => 'Bill details';

  @override
  String get addBill => 'Add transaction';

  @override
  String get annualSummary => 'Annual summary';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get chooseMonth => 'Choose month';

  @override
  String get all => 'All';

  @override
  String get noBills => 'No transactions in this selection.';

  @override
  String get billBasis =>
      'Monthly bills are independent of assets and project entries.';

  @override
  String get billDistribution => 'Category breakdown';

  @override
  String get savedMonth => 'Saved in month:';

  @override
  String get viewMonth => 'View month';

  @override
  String get categories => 'Manage categories';

  @override
  String get newCategory => 'New category';

  @override
  String get categoryInactive => 'Inactive';

  @override
  String get categoryActive => 'Active for new transactions';

  @override
  String get categoryFixed => 'Direction stays fixed after creation.';

  @override
  String get categoryUnavailable =>
      'Choose an active category for this direction.';

  @override
  String get categoryReferenced =>
      'This category is in use. Move its transactions before deleting it.';

  @override
  String get categoryDeleteWarning =>
      'Delete this category and its edit history?';

  @override
  String get moveCategoryWarning =>
      'Move all its transactions to the selected active category, then delete it? Amounts and dates stay unchanged. Each moved transaction gets edit history.';

  @override
  String get moveAndDelete => 'Move and delete';

  @override
  String get replacementCategory => 'Destination category';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get deleteBillWarning =>
      'Delete this transaction and its edit history? Monthly and annual totals will update. Assets stay unchanged.';

  @override
  String get memoTitle => 'Title';

  @override
  String get memoBody => 'Text';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint =>
      'Separate tags with commas; up to 10 tags, 30 characters each.';

  @override
  String get newMemo => 'New memo';

  @override
  String get searchMemos => 'Search title, text or tags';

  @override
  String get noMemos => 'No memos match this selection.';

  @override
  String get deleteMemoWarning =>
      'Delete this memo and its edit history? Financial amounts stay unchanged.';

  @override
  String get memoTextError =>
      'Use a title of 1–200 characters and text up to 20,000 characters.';

  @override
  String get tagError =>
      'Use up to 10 tags, with no more than 30 characters each.';

  @override
  String get recordAxis => 'Record order · business date';

  @override
  String get trendLineHint =>
      'Observation points are spaced equally. Straight lines only illustrate change; they do not show elapsed time or balances between records.';

  @override
  String get annualAxis => 'Month · 1–12';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get dataManagement => 'Data management';

  @override
  String get backupIntro => 'Manage all your local financial records';

  @override
  String get currentData => 'Current data';

  @override
  String get localSaved => 'Saved on this device';

  @override
  String get backupBills => 'Transactions';

  @override
  String get backupAccounts => 'Asset / liability accounts';

  @override
  String get backupProjects => 'All projects';

  @override
  String get lastBill => 'Latest transaction';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupExportHint => 'Save all records and settings to a file';

  @override
  String get backupImport => 'Import & restore';

  @override
  String get backupImportHint => 'Replace all data from a complete backup';

  @override
  String get recentBackup => 'Latest export';

  @override
  String get noBackup => 'No successful export on this installation.';

  @override
  String get backupSafety =>
      'Your records stay on this device. Export regularly before changing phones or reinstalling. Backups contain your full data in plain text; keep them safe.';

  @override
  String get backupSuccess => 'Backup saved';

  @override
  String get backupSuccessBody =>
      'Your complete backup was written and read back successfully.';

  @override
  String get backupFileName => 'File name';

  @override
  String get backupFileSize => 'File size';

  @override
  String get backupLocation => 'Saved location';

  @override
  String get shareBackup => 'Share file';

  @override
  String get done => 'Done';

  @override
  String get backupPreview => 'Restore preview';

  @override
  String get backupDate => 'Backup date';

  @override
  String get backupReplaceWarning =>
      'This replaces ALL current financial records, edit histories and appearance/language settings. A private copy of the current data will be kept so you can undo this restore.';

  @override
  String get confirmRestore => 'Replace and restore';

  @override
  String get restoreSuccess => 'Restore complete';

  @override
  String get restoreSuccessBody =>
      'All records and settings have been restored.';

  @override
  String get recoveryCopy => 'Before-restore copy';

  @override
  String get recoveryCopyHint =>
      'One private copy from before the last successful restore. It is not included in exported files and does not survive uninstalling.';

  @override
  String get noRecoveryCopy => 'No before-restore copy.';

  @override
  String get restoreCopy => 'Preview & restore copy';

  @override
  String get deleteCopy => 'Delete private copy';

  @override
  String get deleteCopyWarning =>
      'Delete only this private restore copy? Your current financial data and exported files stay unchanged.';

  @override
  String get factoryReset => 'Factory reset';

  @override
  String get factoryResetWarning =>
      'Clear all records, edit histories and private restore copies; restore the default zero-balance template and system theme/language. Exported external files will remain.';

  @override
  String get exportFirst => 'Export first';

  @override
  String get confirmReset => 'Confirm clear';

  @override
  String get resetSuccess => 'Factory reset complete';

  @override
  String get resetSuccessBody =>
      'Default projects have zero balances. External backups were kept.';

  @override
  String get backupError => 'Operation not completed';

  @override
  String get invalidBackup =>
      'This is not a valid finance-backup v1 file, or its records/references are invalid. Your current data was kept.';

  @override
  String get backupVersionError =>
      'This backup version is not supported. No data was changed.';

  @override
  String get backupChecksumError =>
      'Backup integrity check failed. No data was changed.';

  @override
  String get backupLimitError =>
      'Backup exceeds the supported limit (32 MiB or 100,000 records). No data was replaced.';

  @override
  String get fileWriteError =>
      'The backup could not be saved and verified. Check storage space and the chosen location. An incomplete new file may need to be removed.';

  @override
  String get fileReadError =>
      'The file could not be read. Select an accessible backup again. No data was changed.';

  @override
  String get filePermissionError =>
      'Access was denied or expired. Select the file again.';

  @override
  String get noSpaceError =>
      'Not enough storage. The operation did not complete. Free some space and retry.';

  @override
  String get fileShareError =>
      'The system share panel could not be opened. The saved backup file is still available.';

  @override
  String get restoreError =>
      'Restore did not complete. The transaction kept your previous data and restore copy.';

  @override
  String get recentRecordError =>
      'The file was saved, but its latest-export information could not be recorded.';

  @override
  String get cachePurgeError =>
      'Data was reset, but private share-cache cleanup is pending. Retry cleanup here; it also resumes at next launch.';

  @override
  String get purgeCache => 'Retry private-cache cleanup';

  @override
  String get backupCancelled => 'Cancelled. Financial data unchanged.';

  @override
  String get backupFilePrefix => 'Finance_backup';

  @override
  String get backupCountsHint =>
      'Includes balances, independent entries, categories, memos, edit histories and settings.';

  @override
  String billCategoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'salary': 'Salary',
      'bonus': 'Bonus',
      'otherIncome': 'Other income',
      'food': 'Food',
      'transport': 'Transport',
      'shopping': 'Shopping',
      'housing': 'Housing',
      'medical': 'Medical',
      'otherExpense': 'Other expenses',
      'other': 'Category',
    });
    return '$_temp0';
  }
}
