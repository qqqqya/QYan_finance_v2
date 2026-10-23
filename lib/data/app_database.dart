import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

abstract class AuditedTable extends Table {
  TextColumn get id => text().withLength(min: 1, max: 36)();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectRow')
class Projects extends AuditedTable {
  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK (type IN ('asset','liability','income_log','expense_log'))",
  )();
  TextColumn get nameKey => text().nullable()();
  TextColumn get customName => text().nullable()();
  TextColumn get categoryKey => text()();
  TextColumn get iconKey => text()();
  TextColumn get colorKey => text()();
  BoolColumn get includeInSummary =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  List<String> get customConstraints => [
    "CHECK ((custom_name IS NOT NULL AND length(trim(custom_name)) > 0) OR name_key IS NOT NULL)",
    "CHECK (type IN ('asset','liability') OR include_in_summary = 0)",
  ];
}

@DataClassName('BalanceRecordRow')
class BalanceRecords extends AuditedTable {
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get balanceMinor => integer().customConstraint(
    'NOT NULL CHECK (balance_minor BETWEEN 0 AND 999999999999)',
  )();
  TextColumn get businessDate => text().withLength(min: 10, max: 10)();
  TextColumn get businessTime => text().withLength(min: 5, max: 5)();
  IntColumn get orderKey =>
      integer().customConstraint('NOT NULL CHECK (order_key >= 0)')();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {projectId, orderKey},
  ];
}

@DataClassName('ProjectEntryRow')
class ProjectEntries extends AuditedTable {
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinor => integer().customConstraint(
    'NOT NULL CHECK (amount_minor BETWEEN 1 AND 999999999999)',
  )();
  TextColumn get businessDate => text().withLength(min: 10, max: 10)();
  TextColumn get businessTime => text().withLength(min: 5, max: 5)();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DataClassName('CategoryRow')
class Categories extends AuditedTable {
  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK (type IN ('income','expense'))",
  )();
  TextColumn get nameKey => text().nullable()();
  TextColumn get customName => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<String> get customConstraints => [
    'CHECK ((custom_name IS NOT NULL AND length(trim(custom_name)) > 0) OR name_key IS NOT NULL)',
  ];
}

@DataClassName('BillRow')
class Bills extends AuditedTable {
  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK (type IN ('income','expense'))",
  )();
  IntColumn get amountMinor => integer().customConstraint(
    'NOT NULL CHECK (amount_minor BETWEEN 1 AND 999999999999)',
  )();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get businessDate => text().withLength(min: 10, max: 10)();
  TextColumn get businessTime => text().withLength(min: 5, max: 5)();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DataClassName('MemoRow')
class Memos extends AuditedTable {
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get businessDate => text().withLength(min: 10, max: 10)();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
}

@DataClassName('EditHistoryRow')
class EditHistories extends Table {
  TextColumn get id => text().withLength(min: 1, max: 36)();
  TextColumn get entityType => text().customConstraint(
    "NOT NULL CHECK (entity_type IN ('project','balanceRecord','projectEntry','bill','category','memo'))",
  )();
  TextColumn get entityId => text()();
  IntColumn get changedAtMs => integer()();
  TextColumn get beforeJson => text()();
  TextColumn get afterJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettingsRow')
class AppPreferences extends Table {
  IntColumn get id => integer().customConstraint('NOT NULL CHECK (id = 1)')();
  TextColumn get themeMode => text().customConstraint(
    "NOT NULL CHECK (theme_mode IN ('system','light','dark'))",
  )();
  TextColumn get languageMode => text().customConstraint(
    "NOT NULL CHECK (language_mode IN ('system','zh-Hans','zh-Hant','en'))",
  )();
  TextColumn get currency =>
      text().customConstraint("NOT NULL CHECK (currency = 'CNY')")();
  TextColumn get timeZone => text().withLength(min: 1, max: 100)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Projects,
    BalanceRecords,
    ProjectEntries,
    Categories,
    Bills,
    Memos,
    EditHistories,
    AppPreferences,
    LocalDataStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      return NativeDatabase.createInBackground(
        File('${directory.path}/finance.sqlite'),
      );
    }),
  );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _installGuards();
    },
    onUpgrade: (migrator, from, to) async {
      if (from == 1 && to == 2) {
        await migrator.createTable(localDataStates);
        return;
      }
      // Add explicit, tested migrations here before incrementing schemaVersion.
      // Unknown upgrades must never destroy or reseed a user's database.
      throw UnsupportedError(
        'No migration has been defined from $from to $to.',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _installGuards() async {
    await customStatement(
      'CREATE INDEX balance_chronology ON balance_records '
      '(project_id, business_date, business_time, order_key)',
    );
    await customStatement(
      'CREATE INDEX bill_month ON bills (business_date, type)',
    );
    await customStatement(
      'CREATE INDEX history_owner ON edit_histories (entity_type, entity_id)',
    );
    for (final operation in ['INSERT', 'UPDATE']) {
      await customStatement('''
        CREATE TRIGGER balance_kind_${operation.toLowerCase()}
        BEFORE $operation ON balance_records
        WHEN NOT EXISTS (SELECT 1 FROM projects WHERE id = NEW.project_id AND type IN ('asset','liability'))
        BEGIN SELECT RAISE(ABORT, 'Balance records require an asset or liability project'); END
      ''');
      await customStatement('''
        CREATE TRIGGER entry_kind_${operation.toLowerCase()}
        BEFORE $operation ON project_entries
        WHEN NOT EXISTS (SELECT 1 FROM projects WHERE id = NEW.project_id AND type IN ('income_log','expense_log'))
        BEGIN SELECT RAISE(ABORT, 'Entries require an independent income or expense project'); END
      ''');
      await customStatement('''
        CREATE TRIGGER bill_category_${operation.toLowerCase()}
        BEFORE $operation ON bills
        WHEN NOT EXISTS (SELECT 1 FROM categories WHERE id = NEW.category_id AND type = NEW.type)
        BEGIN SELECT RAISE(ABORT, 'Bill and category directions must match'); END
      ''');
    }
    await customStatement('''
      CREATE TRIGGER project_kind_immutable BEFORE UPDATE OF type ON projects
      WHEN OLD.type <> NEW.type AND (
        EXISTS (SELECT 1 FROM balance_records WHERE project_id = OLD.id) OR
        EXISTS (SELECT 1 FROM project_entries WHERE project_id = OLD.id)
      ) BEGIN SELECT RAISE(ABORT, 'A project with records cannot change type'); END
    ''');
    await customStatement('''
      CREATE TRIGGER category_kind_immutable BEFORE UPDATE OF type ON categories
      WHEN OLD.type <> NEW.type AND EXISTS (SELECT 1 FROM bills WHERE category_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'A referenced category cannot change direction'); END
    ''');
    for (final item in {
      'projects': 'project',
      'balance_records': 'balanceRecord',
      'project_entries': 'projectEntry',
      'bills': 'bill',
      'categories': 'category',
      'memos': 'memo',
    }.entries) {
      await customStatement('''
        CREATE TRIGGER cleanup_${item.key} AFTER DELETE ON ${item.key}
        BEGIN DELETE FROM edit_histories
          WHERE entity_type = '${item.value}' AND entity_id = OLD.id; END
      ''');
    }
  }
}

/// Local operational metadata, deliberately excluded from portable backups.
@DataClassName('LocalDataStateRow')
class LocalDataStates extends Table {
  IntColumn get id => integer().customConstraint('NOT NULL CHECK (id = 1)')();
  TextColumn get recoveryJson => text().nullable()();
  TextColumn get lastExportName => text().nullable()();
  TextColumn get lastExportUri => text().nullable()();
  TextColumn get lastExportLocation => text().nullable()();
  IntColumn get lastExportBytes => integer().nullable()();
  IntColumn get lastExportAtMs => integer().nullable()();
  BoolColumn get pendingCachePurge =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
