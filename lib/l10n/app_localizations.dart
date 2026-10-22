import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total assets'**
  String get totalAssets;

  /// No description provided for @totalLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Total liabilities'**
  String get totalLiabilities;

  /// No description provided for @netAssets.
  ///
  /// In en, this message translates to:
  /// **'Net assets'**
  String get netAssets;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My projects'**
  String get myProjects;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Your records are stored only on this device.'**
  String get localOnly;

  /// No description provided for @includedInAssets.
  ///
  /// In en, this message translates to:
  /// **'Included in total assets'**
  String get includedInAssets;

  /// No description provided for @excludedFromAssets.
  ///
  /// In en, this message translates to:
  /// **'Excluded from total assets'**
  String get excludedFromAssets;

  /// No description provided for @liabilityBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get liabilityBalance;

  /// No description provided for @independentIncome.
  ///
  /// In en, this message translates to:
  /// **'Independent income · cumulative'**
  String get independentIncome;

  /// No description provided for @independentExpense.
  ///
  /// In en, this message translates to:
  /// **'Independent expense · cumulative'**
  String get independentExpense;

  /// No description provided for @appearanceAndLanguage.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get appearanceAndLanguage;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @localData.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get localData;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Book time zone'**
  String get timeZone;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Your setting could not be saved. Please try again.'**
  String get saveError;

  /// No description provided for @dataError.
  ///
  /// In en, this message translates to:
  /// **'Your local data could not be read. Please reopen the app to retry.'**
  String get dataError;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'The app could not open its local database. Your existing records have been kept.'**
  String get startupError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'{key, select, cmb{China Merchants Bank} bocom{Bank of Communications} alipay{Alipay} cash{Cash} fund{Funds} investment{Investments} liability{Liabilities} largeIncome{Large income} largeExpense{Large expenses} other{Project}}'**
  String projectName(String key);

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectDetails;

  /// No description provided for @projectType.
  ///
  /// In en, this message translates to:
  /// **'Project type'**
  String get projectType;

  /// No description provided for @typeAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get typeAsset;

  /// No description provided for @typeLiability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get typeLiability;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Independent income'**
  String get typeIncome;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Independent expense'**
  String get typeExpense;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @customCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom category (optional)'**
  String get customCategory;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get initialBalance;

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Actual balance after update'**
  String get balanceAmount;

  /// No description provided for @entryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get entryAmount;

  /// No description provided for @businessDate.
  ///
  /// In en, this message translates to:
  /// **'Business date · YYYY-MM-DD'**
  String get businessDate;

  /// No description provided for @businessTime.
  ///
  /// In en, this message translates to:
  /// **'Business time · HH:mm'**
  String get businessTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @deleteProjectWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this project, all its records and edit history? Totals and trends will be recalculated. This cannot be undone.'**
  String get deleteProjectWarning;

  /// No description provided for @deleteRecordWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this record and its edit history? Its amount will be removed from calculations.'**
  String get deleteRecordWarning;

  /// No description provided for @clearRecords.
  ///
  /// In en, this message translates to:
  /// **'Clear all records'**
  String get clearRecords;

  /// No description provided for @clearRecordsWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete all records and their edit history in this project? Its amount will become zero. The project itself stays.'**
  String get clearRecordsWarning;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get history;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear edit history'**
  String get clearHistory;

  /// No description provided for @historyDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Clear this object\'s edit history? Current records and amounts will remain unchanged.'**
  String get historyDeleteWarning;

  /// No description provided for @deleteHistoryWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this edit history item? The current record and amount will stay unchanged.'**
  String get deleteHistoryWarning;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No edits recorded.'**
  String get historyEmpty;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @changedAt.
  ///
  /// In en, this message translates to:
  /// **'Edited at'**
  String get changedAt;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last edited'**
  String get updatedAt;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Amount is zero.'**
  String get noRecords;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get allMonths;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Filter month · YYYY-MM'**
  String get selectMonth;

  /// No description provided for @updateBalance.
  ///
  /// In en, this message translates to:
  /// **'Update balance'**
  String get updateBalance;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @typeLocked.
  ///
  /// In en, this message translates to:
  /// **'Projects with records cannot change type.'**
  String get typeLocked;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of 1–80 characters.'**
  String get invalidName;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Use a valid amount with at most 2 decimals, up to 9,999,999,999.99. Entries must be greater than zero.'**
  String get invalidAmount;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Use a valid date and time in the displayed format.'**
  String get invalidDate;

  /// No description provided for @futureDate.
  ///
  /// In en, this message translates to:
  /// **'Business time cannot be in the future of the book time zone.'**
  String get futureDate;

  /// No description provided for @invalidText.
  ///
  /// In en, this message translates to:
  /// **'Check category and note length (note: max 2,000 characters).'**
  String get invalidText;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'The change was not saved. Please try again.'**
  String get operationFailed;

  /// No description provided for @staleOrder.
  ///
  /// In en, this message translates to:
  /// **'Projects changed while sorting. Reload and try again.'**
  String get staleOrder;

  /// No description provided for @missingProject.
  ///
  /// In en, this message translates to:
  /// **'This project or record no longer exists.'**
  String get missingProject;

  /// No description provided for @includeAsset.
  ///
  /// In en, this message translates to:
  /// **'Include in total assets'**
  String get includeAsset;

  /// No description provided for @includeLiability.
  ///
  /// In en, this message translates to:
  /// **'Include in total liabilities'**
  String get includeLiability;

  /// No description provided for @recordedChange.
  ///
  /// In en, this message translates to:
  /// **'Change from previous balance'**
  String get recordedChange;

  /// No description provided for @assetComposition.
  ///
  /// In en, this message translates to:
  /// **'Asset composition'**
  String get assetComposition;

  /// No description provided for @liabilityComposition.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get liabilityComposition;

  /// No description provided for @assetTrend.
  ///
  /// In en, this message translates to:
  /// **'Balance trend'**
  String get assetTrend;

  /// No description provided for @manualBasis.
  ///
  /// In en, this message translates to:
  /// **'Based on manual records of currently included projects.'**
  String get manualBasis;

  /// No description provided for @emptyChart.
  ///
  /// In en, this message translates to:
  /// **'No positive balances to display.'**
  String get emptyChart;

  /// No description provided for @noTrend.
  ///
  /// In en, this message translates to:
  /// **'No balance records in this period.'**
  String get noTrend;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30;

  /// No description provided for @months12.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get months12;

  /// No description provided for @pointValues.
  ///
  /// In en, this message translates to:
  /// **'Date / time and balance'**
  String get pointValues;

  /// No description provided for @amountAxis.
  ///
  /// In en, this message translates to:
  /// **'Amount · CNY'**
  String get amountAxis;

  /// No description provided for @dateAxis.
  ///
  /// In en, this message translates to:
  /// **'Business date'**
  String get dateAxis;

  /// No description provided for @unsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedTitle;

  /// No description provided for @unsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Save your changes before leaving?'**
  String get unsavedBody;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get continueEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @sortHint.
  ///
  /// In en, this message translates to:
  /// **'Long press and drag cards to reorder.'**
  String get sortHint;

  /// No description provided for @sortProjects.
  ///
  /// In en, this message translates to:
  /// **'Reorder projects'**
  String get sortProjects;

  /// No description provided for @bankCategory.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get bankCategory;

  /// No description provided for @walletCategory.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletCategory;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @colorNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get colorNeutral;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @monthlyBills.
  ///
  /// In en, this message translates to:
  /// **'Monthly bills'**
  String get monthlyBills;

  /// No description provided for @memos.
  ///
  /// In en, this message translates to:
  /// **'Finance memos'**
  String get memos;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @surplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @billDetails.
  ///
  /// In en, this message translates to:
  /// **'Bill details'**
  String get billDetails;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addBill;

  /// No description provided for @annualSummary.
  ///
  /// In en, this message translates to:
  /// **'Annual summary'**
  String get annualSummary;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @chooseMonth.
  ///
  /// In en, this message translates to:
  /// **'Choose month'**
  String get chooseMonth;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noBills.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this selection.'**
  String get noBills;

  /// No description provided for @billBasis.
  ///
  /// In en, this message translates to:
  /// **'Monthly bills are independent of assets and project entries.'**
  String get billBasis;

  /// No description provided for @billDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown'**
  String get billDistribution;

  /// No description provided for @savedMonth.
  ///
  /// In en, this message translates to:
  /// **'Saved in month:'**
  String get savedMonth;

  /// No description provided for @viewMonth.
  ///
  /// In en, this message translates to:
  /// **'View month'**
  String get viewMonth;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get categories;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @categoryInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get categoryInactive;

  /// No description provided for @categoryActive.
  ///
  /// In en, this message translates to:
  /// **'Active for new transactions'**
  String get categoryActive;

  /// No description provided for @categoryFixed.
  ///
  /// In en, this message translates to:
  /// **'Direction stays fixed after creation.'**
  String get categoryFixed;

  /// No description provided for @categoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Choose an active category for this direction.'**
  String get categoryUnavailable;

  /// No description provided for @categoryReferenced.
  ///
  /// In en, this message translates to:
  /// **'This category is in use. Move its transactions before deleting it.'**
  String get categoryReferenced;

  /// No description provided for @categoryDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this category and its edit history?'**
  String get categoryDeleteWarning;

  /// No description provided for @moveCategoryWarning.
  ///
  /// In en, this message translates to:
  /// **'Move all its transactions to the selected active category, then delete it? Amounts and dates stay unchanged. Each moved transaction gets edit history.'**
  String get moveCategoryWarning;

  /// No description provided for @moveAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Move and delete'**
  String get moveAndDelete;

  /// No description provided for @replacementCategory.
  ///
  /// In en, this message translates to:
  /// **'Destination category'**
  String get replacementCategory;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @deleteBillWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction and its edit history? Monthly and annual totals will update. Assets stay unchanged.'**
  String get deleteBillWarning;

  /// No description provided for @memoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get memoTitle;

  /// No description provided for @memoBody.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get memoBody;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate tags with commas; up to 10 tags, 30 characters each.'**
  String get tagsHint;

  /// No description provided for @newMemo.
  ///
  /// In en, this message translates to:
  /// **'New memo'**
  String get newMemo;

  /// No description provided for @searchMemos.
  ///
  /// In en, this message translates to:
  /// **'Search title, text or tags'**
  String get searchMemos;

  /// No description provided for @noMemos.
  ///
  /// In en, this message translates to:
  /// **'No memos match this selection.'**
  String get noMemos;

  /// No description provided for @deleteMemoWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this memo and its edit history? Financial amounts stay unchanged.'**
  String get deleteMemoWarning;

  /// No description provided for @memoTextError.
  ///
  /// In en, this message translates to:
  /// **'Use a title of 1–200 characters and text up to 20,000 characters.'**
  String get memoTextError;

  /// No description provided for @tagError.
  ///
  /// In en, this message translates to:
  /// **'Use up to 10 tags, with no more than 30 characters each.'**
  String get tagError;

  /// No description provided for @recordAxis.
  ///
  /// In en, this message translates to:
  /// **'Record order · business date'**
  String get recordAxis;

  /// No description provided for @trendLineHint.
  ///
  /// In en, this message translates to:
  /// **'Observation points are spaced equally. Straight lines only illustrate change; they do not show elapsed time or balances between records.'**
  String get trendLineHint;

  /// No description provided for @annualAxis.
  ///
  /// In en, this message translates to:
  /// **'Month · 1–12'**
  String get annualAxis;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @billCategoryName.
  ///
  /// In en, this message translates to:
  /// **'{key, select, salary{Salary} bonus{Bonus} otherIncome{Other income} food{Food} transport{Transport} shopping{Shopping} housing{Housing} medical{Medical} otherExpense{Other expenses} other{Category}}'**
  String billCategoryName(String key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
