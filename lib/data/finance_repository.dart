import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/business_date.dart';
import '../core/money.dart';
import '../domain/app_settings.dart';
import 'app_database.dart';
import 'workspace.dart';

const defaultProjectSeeds = [
  ('asset', 'cmb', 'bank'),
  ('asset', 'bocom', 'bank'),
  ('asset', 'alipay', 'wallet'),
  ('asset', 'cash', 'cash'),
  ('asset', 'fund', 'fund'),
  ('asset', 'investment', 'investment'),
  ('liability', 'liability', 'liability'),
  ('income_log', 'largeIncome', 'income'),
  ('expense_log', 'largeExpense', 'expense'),
];

const defaultCategorySeeds = [
  ('income', 'salary'),
  ('income', 'bonus'),
  ('income', 'otherIncome'),
  ('expense', 'food'),
  ('expense', 'transport'),
  ('expense', 'shopping'),
  ('expense', 'housing'),
  ('expense', 'medical'),
  ('expense', 'otherExpense'),
];

final class FinanceRepository {
  FinanceRepository(this.database, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final AppDatabase database;
  final DateTime Function() clock;
  static const _uuid = Uuid();

  // One SELECT observes one committed SQLite snapshot, without starting a
  // transaction inside a database notification callback.
  Stream<Workspace> watchWorkspace() => database
      .customSelect(
        '''
    SELECT 'project' AS kind, json_object(
      'id',id,'createdAtMs',created_at_ms,'updatedAtMs',updated_at_ms,
      'type',type,'nameKey',name_key,'customName',custom_name,
      'categoryKey',category_key,'iconKey',icon_key,'colorKey',color_key,
      'includeInSummary',include_in_summary,'sortOrder',sort_order,'note',note) AS payload FROM projects
    UNION ALL SELECT 'balance', json_object(
      'id',id,'createdAtMs',created_at_ms,'updatedAtMs',updated_at_ms,
      'projectId',project_id,'balanceMinor',balance_minor,'businessDate',business_date,
      'businessTime',business_time,'orderKey',order_key,'note',note) FROM balance_records
    UNION ALL SELECT 'entry', json_object(
      'id',id,'createdAtMs',created_at_ms,'updatedAtMs',updated_at_ms,
      'projectId',project_id,'amountMinor',amount_minor,'businessDate',business_date,
      'businessTime',business_time,'note',note) FROM project_entries
  ''',
        readsFrom: {
          database.projects,
          database.balanceRecords,
          database.projectEntries,
        },
      )
      .watch()
      .map((rows) {
        final projects = <ProjectRow>[],
            balances = <BalanceRecordRow>[],
            entries = <ProjectEntryRow>[];
        for (final row in rows) {
          final payload =
              jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
          switch (row.read<String>('kind')) {
            case 'project':
              payload['includeInSummary'] = payload['includeInSummary'] == 1;
              projects.add(ProjectRow.fromJson(payload));
            case 'balance':
              balances.add(BalanceRecordRow.fromJson(payload));
            case 'entry':
              entries.add(ProjectEntryRow.fromJson(payload));
          }
        }
        projects.sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order != 0 ? order : a.id.compareTo(b.id);
        });
        return Workspace(projects, balances, entries);
      });

  Future<ProjectRow> _project(String id) async {
    final value = await (database.select(
      database.projects,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (value == null) throw const FinanceValidation('missing');
    return value;
  }

  Future<BusinessMoment> nowInBook() async {
    final settings = await database.select(database.appPreferences).getSingle();
    return BusinessMoment.inZone(clock(), settings.timeZone);
  }

  Future<void> _validateMoment(BusinessMoment moment) async {
    if (moment.compareTo(await nowInBook()) > 0) {
      throw const FinanceValidation('future');
    }
  }

  void _validateDraft(ProjectDraft draft) {
    if (draft.name.trim().isEmpty || draft.name.trim().length > 80) {
      throw const FinanceValidation('name');
    }
    if (!{
      'asset',
      'liability',
      'income_log',
      'expense_log',
    }.contains(draft.type)) {
      throw const FinanceValidation('type');
    }
    final categoryText = draft.categoryKey.startsWith('custom:')
        ? draft.categoryKey.substring(7)
        : draft.categoryKey;
    if (categoryText.trim().isEmpty ||
        categoryText.length > 80 ||
        draft.note.length > 2000) {
      throw const FinanceValidation('text');
    }
  }

  Map<String, Object?> _payload(Map<String, dynamic> raw) {
    final result = <String, Object?>{...raw};
    for (final field in ['createdAt', 'updatedAt']) {
      final millis = result.remove('${field}Ms');
      if (millis is int) {
        result[field] = DateTime.fromMillisecondsSinceEpoch(
          millis,
          isUtc: true,
        ).toIso8601String();
      }
    }
    return result;
  }

  Future<void> _history(
    String type,
    String id,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) async {
    await database
        .into(database.editHistories)
        .insert(
          EditHistoriesCompanion.insert(
            id: _uuid.v4(),
            entityType: type,
            entityId: id,
            changedAtMs: clock().toUtc().millisecondsSinceEpoch,
            beforeJson: jsonEncode(_payload(before)),
            afterJson: jsonEncode(_payload(after)),
          ),
        );
  }

  Future<String> createProject(ProjectDraft draft) =>
      database.transaction(() async {
        _validateDraft(draft);
        if (draft.initialMinor < 0 || draft.initialMinor > maxRecordMinor) {
          throw const FinanceValidation('amount');
        }
        final moment = draft.initialMoment ?? await nowInBook();
        await _validateMoment(moment);
        final existing = await database.select(database.projects).get();
        final order =
            existing.fold<int>(
              -1,
              (max, p) => p.sortOrder > max ? p.sortOrder : max,
            ) +
            1;
        final timestamp = clock().toUtc().millisecondsSinceEpoch;
        final id = _uuid.v4();
        await database
            .into(database.projects)
            .insert(
              ProjectsCompanion.insert(
                id: id,
                type: draft.type,
                customName: Value(draft.name.trim()),
                categoryKey: draft.categoryKey.trim(),
                iconKey: draft.iconKey,
                colorKey: draft.colorKey,
                includeInSummary: Value(
                  isBalanceType(draft.type) && draft.included,
                ),
                sortOrder: order,
                note: Value(draft.note.trim()),
                createdAtMs: timestamp,
                updatedAtMs: timestamp,
              ),
            );
        if (isBalanceType(draft.type)) {
          await _saveRecord(
            id,
            amount: draft.initialMinor,
            moment: moment,
            note: '',
          );
        }
        return id;
      });
  Future<void> editProject(String id, ProjectDraft draft) =>
      database.transaction(() async {
        _validateDraft(draft);
        final previous = await _project(id);
        if (previous.type != draft.type) {
          final balances = await (database.select(
            database.balanceRecords,
          )..where((r) => r.projectId.equals(id))).get();
          final entries = await (database.select(
            database.projectEntries,
          )..where((r) => r.projectId.equals(id))).get();
          if (balances.isNotEmpty || entries.isNotEmpty) {
            throw const FinanceValidation('lockedType');
          }
        }
        final keepName = draft.keepBuiltInName && previous.nameKey != null;
        final next = previous.copyWith(
          type: draft.type,
          nameKey: Value(keepName ? previous.nameKey : null),
          customName: Value(keepName ? null : draft.name.trim()),
          categoryKey: draft.categoryKey.trim(),
          iconKey: draft.iconKey,
          colorKey: draft.colorKey,
          includeInSummary: isBalanceType(draft.type) && draft.included,
          note: draft.note.trim(),
        );
        if (jsonEncode(next.toJson()) == jsonEncode(previous.toJson())) return;
        final saved = next.copyWith(
          updatedAtMs: clock().toUtc().millisecondsSinceEpoch,
        );
        await database.update(database.projects).replace(saved);
        await _history('project', id, previous.toJson(), saved.toJson());
      });
  Future<String> saveRecord(
    String projectId, {
    String? recordId,
    required int amount,
    required BusinessMoment moment,
    String note = '',
  }) => database.transaction(
    () => _saveRecord(
      projectId,
      recordId: recordId,
      amount: amount,
      moment: moment,
      note: note,
    ),
  );
  Future<String> _saveRecord(
    String projectId, {
    String? recordId,
    required int amount,
    required BusinessMoment moment,
    required String note,
  }) async {
    final project = await _project(projectId);
    final balance = isBalanceType(project.type);
    if (amount < (balance ? 0 : 1) || amount > maxRecordMinor) {
      throw const FinanceValidation('amount');
    }
    if (note.length > 2000) throw const FinanceValidation('text');
    await _validateMoment(moment);
    final timestamp = clock().toUtc().millisecondsSinceEpoch;
    final id = recordId ?? _uuid.v4();
    if (balance) {
      if (recordId == null) {
        final previous =
            await (database.select(database.balanceRecords)
                  ..where((r) => r.projectId.equals(projectId))
                  ..orderBy([(r) => OrderingTerm.desc(r.orderKey)])
                  ..limit(1))
                .getSingleOrNull();
        await database
            .into(database.balanceRecords)
            .insert(
              BalanceRecordsCompanion.insert(
                id: id,
                projectId: projectId,
                balanceMinor: amount,
                businessDate: moment.date.toString(),
                businessTime: moment.time,
                orderKey: checkedSumMinor([previous?.orderKey ?? -1, 1]),
                note: Value(note.trim()),
                createdAtMs: timestamp,
                updatedAtMs: timestamp,
              ),
            );
      } else {
        final previous =
            await (database.select(database.balanceRecords)..where(
                  (r) => r.id.equals(id) & r.projectId.equals(projectId),
                ))
                .getSingleOrNull();
        if (previous == null) throw const FinanceValidation('missing');
        final next = previous.copyWith(
          balanceMinor: amount,
          businessDate: moment.date.toString(),
          businessTime: moment.time,
          note: note.trim(),
        );
        if (jsonEncode(next.toJson()) == jsonEncode(previous.toJson())) {
          return id;
        }
        final saved = next.copyWith(updatedAtMs: timestamp);
        await database.update(database.balanceRecords).replace(saved);
        await _history('balanceRecord', id, previous.toJson(), saved.toJson());
      }
    } else {
      if (recordId == null) {
        await database
            .into(database.projectEntries)
            .insert(
              ProjectEntriesCompanion.insert(
                id: id,
                projectId: projectId,
                amountMinor: amount,
                businessDate: moment.date.toString(),
                businessTime: moment.time,
                note: Value(note.trim()),
                createdAtMs: timestamp,
                updatedAtMs: timestamp,
              ),
            );
      } else {
        final previous =
            await (database.select(database.projectEntries)..where(
                  (r) => r.id.equals(id) & r.projectId.equals(projectId),
                ))
                .getSingleOrNull();
        if (previous == null) throw const FinanceValidation('missing');
        final next = previous.copyWith(
          amountMinor: amount,
          businessDate: moment.date.toString(),
          businessTime: moment.time,
          note: note.trim(),
        );
        if (jsonEncode(next.toJson()) == jsonEncode(previous.toJson())) {
          return id;
        }
        final saved = next.copyWith(updatedAtMs: timestamp);
        await database.update(database.projectEntries).replace(saved);
        await _history('projectEntry', id, previous.toJson(), saved.toJson());
      }
    }
    return id;
  }

  Future<void> deleteRecord(String projectId, String id) =>
      database.transaction(() async {
        final project = await _project(projectId);
        if (isBalanceType(project.type)) {
          await (database.delete(database.balanceRecords)
                ..where((r) => r.id.equals(id) & r.projectId.equals(projectId)))
              .go();
        } else {
          await (database.delete(database.projectEntries)
                ..where((r) => r.id.equals(id) & r.projectId.equals(projectId)))
              .go();
        }
      });
  Future<void> clearRecords(String projectId) => database.transaction(() async {
    await _project(projectId);
    await (database.delete(
      database.balanceRecords,
    )..where((r) => r.projectId.equals(projectId))).go();
    await (database.delete(
      database.projectEntries,
    )..where((r) => r.projectId.equals(projectId))).go();
  });
  Future<void> deleteProject(String id) => database.transaction(() async {
    await (database.delete(
      database.projects,
    )..where((p) => p.id.equals(id))).go();
  });
  Future<void> reorderProjects(List<String> ids) =>
      database.transaction(() async {
        final existing = await database.select(database.projects).get();
        if (ids.toSet().length != ids.length ||
            ids.length != existing.length ||
            !ids.toSet().containsAll(existing.map((p) => p.id))) {
          throw const FinanceValidation('staleOrder');
        }
        for (var i = 0; i < ids.length; i++) {
          await (database.update(database.projects)
                ..where((p) => p.id.equals(ids[i])))
              .write(ProjectsCompanion(sortOrder: Value(i)));
        }
      });
  Stream<List<EditHistoryRow>> watchHistory(String type, String id) =>
      (database.select(database.editHistories)
            ..where((h) => h.entityType.equals(type) & h.entityId.equals(id))
            ..orderBy([
              (h) => OrderingTerm.desc(h.changedAtMs),
              (h) => OrderingTerm.desc(h.id),
            ]))
          .watch();
  Future<void> deleteHistory(String id) => database.transaction(() async {
    await (database.delete(
      database.editHistories,
    )..where((h) => h.id.equals(id))).go();
  });
  Future<void> clearHistory(String type, String id) =>
      database.transaction(() async {
        await (database.delete(database.editHistories)
              ..where((h) => h.entityType.equals(type) & h.entityId.equals(id)))
            .go();
      });

  Future<void> initialize(String timeZone) async {
    final moment = BusinessMoment.inZone(clock(), timeZone);
    await database.transaction(() async {
      final existing = await database
          .select(database.appPreferences)
          .getSingleOrNull();
      if (existing != null) return;
      final timestamp = clock().toUtc().millisecondsSinceEpoch;
      await database
          .into(database.appPreferences)
          .insert(
            AppPreferencesCompanion.insert(
              id: const Value(1),
              themeMode: 'system',
              languageMode: 'system',
              currency: 'CNY',
              timeZone: timeZone,
            ),
          );
      for (var index = 0; index < defaultProjectSeeds.length; index++) {
        final (type, key, category) = defaultProjectSeeds[index];
        final id = _uuid.v4();
        await database
            .into(database.projects)
            .insert(
              ProjectsCompanion.insert(
                id: id,
                createdAtMs: timestamp,
                updatedAtMs: timestamp,
                type: type,
                nameKey: Value(key),
                categoryKey: category,
                iconKey: category,
                colorKey: 'neutral',
                sortOrder: index,
                includeInSummary: Value(type == 'asset' || type == 'liability'),
              ),
            );
        if (type == 'asset' || type == 'liability') {
          await database
              .into(database.balanceRecords)
              .insert(
                BalanceRecordsCompanion.insert(
                  id: _uuid.v4(),
                  createdAtMs: timestamp,
                  updatedAtMs: timestamp,
                  projectId: id,
                  balanceMinor: 0,
                  businessDate: moment.date.toString(),
                  businessTime: moment.time,
                  orderKey: 0,
                ),
              );
        }
      }
      for (var index = 0; index < defaultCategorySeeds.length; index++) {
        final (type, key) = defaultCategorySeeds[index];
        await database
            .into(database.categories)
            .insert(
              CategoriesCompanion.insert(
                id: _uuid.v4(),
                createdAtMs: timestamp,
                updatedAtMs: timestamp,
                type: type,
                nameKey: Value(key),
                sortOrder: index,
              ),
            );
      }
    });
  }

  Stream<AppSettings> watchSettings() => database
      .select(database.appPreferences)
      .watchSingle()
      .map(
        (row) => AppSettings(
          appearance: Appearance.values.byName(row.themeMode),
          language: AppLanguage.fromCode(row.languageMode),
          timeZone: row.timeZone,
        ),
      );

  Future<void> setAppearance(Appearance appearance) =>
      database.transaction(() async {
        await (database.update(database.appPreferences)
              ..where((row) => row.id.equals(1)))
            .write(AppPreferencesCompanion(themeMode: Value(appearance.name)));
      });

  Future<void> setLanguage(AppLanguage language) =>
      database.transaction(() async {
        await (database.update(database.appPreferences)
              ..where((row) => row.id.equals(1)))
            .write(AppPreferencesCompanion(languageMode: Value(language.code)));
      });

  Stream<List<ProjectSummary>> watchDashboard() {
    // Write boundaries reject future business times. Do not capture the current
    // minute here: a long-lived subscription must include later saved balances.
    return database
        .customSelect(
          '''
      SELECT p.*,
        CASE WHEN p.type IN ('asset','liability') THEN COALESCE((
          SELECT b.balance_minor FROM balance_records b WHERE b.project_id = p.id
          ORDER BY b.business_date DESC, b.business_time DESC, b.order_key DESC LIMIT 1
        ), 0) ELSE COALESCE((
          SELECT SUM(e.amount_minor) FROM project_entries e WHERE e.project_id = p.id
        ), 0) END AS current_minor
      FROM projects p ORDER BY p.sort_order, p.id
    ''',
          readsFrom: {
            database.projects,
            database.balanceRecords,
            database.projectEntries,
          },
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ProjectSummary(
                  id: row.read<String>('id'),
                  type: row.read<String>('type'),
                  nameKey: row.readNullable<String>('name_key'),
                  customName: row.readNullable<String>('custom_name'),
                  included: row.read<bool>('include_in_summary'),
                  amountMinor: row.read<int>('current_minor'),
                ),
              )
              .toList(growable: false),
        );
  }
}
