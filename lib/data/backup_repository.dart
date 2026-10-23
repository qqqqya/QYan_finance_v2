import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/backup_document.dart';
import 'app_database.dart';
import 'finance_repository.dart';

class BackupStatus {
  const BackupStatus(
    this.bills,
    this.accounts,
    this.projects,
    this.memos,
    this.latestBill,
    this.local,
    this.hasRecovery,
  );
  final int bills, accounts, projects, memos;
  final String? latestBill;
  final LocalDataStateRow? local;
  final bool hasRecovery;
}

class BackupRepository {
  BackupRepository(this.finance);
  final FinanceRepository finance;
  AppDatabase get db => finance.database;
  Stream<BackupStatus> watchStatus() => db
      .customSelect(
        '''
    SELECT (SELECT COUNT(*) FROM bills) AS bills,
      (SELECT COUNT(*) FROM projects WHERE type IN ('asset','liability')) AS accounts,
      (SELECT COUNT(*) FROM projects) AS projects, (SELECT COUNT(*) FROM memos) AS memos,
      (SELECT MAX(business_date || ' ' || business_time) FROM bills) AS latest_bill,
      EXISTS(SELECT 1 FROM local_data_states WHERE recovery_json IS NOT NULL) AS has_recovery,
      (SELECT json_object('id',id,'recoveryJson',NULL,'lastExportName',last_export_name,
        'lastExportUri',last_export_uri,'lastExportLocation',last_export_location,
        'lastExportBytes',last_export_bytes,'lastExportAtMs',last_export_at_ms,
        'pendingCachePurge',pending_cache_purge) FROM local_data_states WHERE id=1) AS local
  ''',
        readsFrom: {db.bills, db.projects, db.memos, db.localDataStates},
      )
      .watch()
      .map((rows) {
        final r = rows.single, raw = r.readNullable<String>('local');
        LocalDataStateRow? local;
        if (raw != null) {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          m['pendingCachePurge'] = m['pendingCachePurge'] == 1;
          local = LocalDataStateRow.fromJson(m);
        }
        return BackupStatus(
          r.read<int>('bills'),
          r.read<int>('accounts'),
          r.read<int>('projects'),
          r.read<int>('memos'),
          r.readNullable<String>('latest_bill'),
          local,
          r.read<int>('has_recovery') == 1,
        );
      });
  Future<BackupDocument> capture() => db.transaction(_capture);
  Future<BackupDocument> _capture() async {
    final data = <String, dynamic>{};
    data['projects'] =
        (await (db.select(
              db.projects,
            )..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
            .map((r) => portableFields(r.toJson()))
            .toList();
    data['balanceRecords'] =
        (await (db.select(
              db.balanceRecords,
            )..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
            .map((r) => portableFields(r.toJson()))
            .toList();
    data['projectEntries'] =
        (await (db.select(
              db.projectEntries,
            )..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
            .map((r) => portableFields(r.toJson()))
            .toList();
    data['bills'] =
        (await (db.select(
              db.bills,
            )..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
            .map((r) => portableFields(r.toJson()))
            .toList();
    data['categories'] =
        (await (db.select(
              db.categories,
            )..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
            .map((r) => portableFields(r.toJson()))
            .toList();
    data['memos'] =
        (await (db.select(
          db.memos,
        )..orderBy([(r) => OrderingTerm.asc(r.id)])).get()).map((r) {
          final m = portableFields(r.toJson());
          m.remove('tagsJson');
          m['tags'] = jsonDecode(r.tagsJson);
          return m;
        }).toList();
    data['editHistory'] =
        (await (db.select(
              db.editHistories,
            )..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
            .map(
              (r) => {
                'id': r.id,
                'entityType': r.entityType,
                'entityId': r.entityId,
                'changedAt': DateTime.fromMillisecondsSinceEpoch(
                  r.changedAtMs,
                  isUtc: true,
                ).toIso8601String(),
                'before': jsonDecode(r.beforeJson),
                'after': jsonDecode(r.afterJson),
              },
            )
            .toList();
    final prefs = await db.select(db.appPreferences).getSingle();
    data['settings'] = {
      'themeMode': prefs.themeMode,
      'languageMode': prefs.languageMode,
      'currency': prefs.currency,
      'timeZone': prefs.timeZone,
    };
    final root = signedBackup({
      'format': 'finance-backup',
      'schemaVersion': 1,
      'appVersion': backupAppVersion,
      'exportedAt': DateTime.fromMillisecondsSinceEpoch(
        finance.clock().millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String(),
      'currency': prefs.currency,
      'timeZone': prefs.timeZone,
      'data': data,
    });
    final bytes = Uint8List.fromList(utf8.encode(canonicalJson(root)));
    // The exporter obeys exactly the same resource and business limits as import.
    return BackupDocument.decode(bytes, now: finance.clock());
  }

  Future<void> _state(LocalDataStatesCompanion changes) async {
    await db
        .into(db.localDataStates)
        .insert(
          LocalDataStatesCompanion.insert(id: const Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
    await (db.update(
      db.localDataStates,
    )..where((r) => r.id.equals(1))).write(changes);
  }

  Future<void> recordExport({
    required String name,
    required String uri,
    required String location,
    required int bytes,
    required DateTime at,
  }) => db.transaction(
    () => _state(
      LocalDataStatesCompanion(
        lastExportName: Value(name),
        lastExportUri: Value(uri),
        lastExportLocation: Value(location),
        lastExportBytes: Value(bytes),
        lastExportAtMs: Value(at.toUtc().millisecondsSinceEpoch),
      ),
    ),
  );
  Future<BackupDocument?> recovery() async {
    final row = await db.select(db.localDataStates).getSingleOrNull();
    return row?.recoveryJson == null
        ? null
        : BackupDocument.decode(
            Uint8List.fromList(utf8.encode(row!.recoveryJson!)),
            now: finance.clock(),
          );
  }

  Future<void> deleteRecovery() => db.transaction(
    () => _state(const LocalDataStatesCompanion(recoveryJson: Value(null))),
  );
  Future<void> restore(BackupDocument document) async {
    final validated = BackupDocument.decode(
      document.bytes,
      now: finance.clock(),
    );
    await db.transaction(() async {
      final before = await _capture();
      // Copy and replacement commit together: crash/failure leaves both untouched.
      await _state(
        LocalDataStatesCompanion(
          recoveryJson: Value(utf8.decode(before.bytes)),
        ),
      );
      await _clear();
      await _insert(validated);
      if ((await db.customSelect('PRAGMA foreign_key_check').get())
          .isNotEmpty) {
        throw const BackupFailure('invalidBackup');
      }
    });
  }

  Future<void> _clear() async {
    await db.delete(db.editHistories).go();
    await db.delete(db.bills).go();
    await db.delete(db.balanceRecords).go();
    await db.delete(db.projectEntries).go();
    await db.delete(db.memos).go();
    await db.delete(db.projects).go();
    await db.delete(db.categories).go();
    await db.delete(db.appPreferences).go();
  }

  Future<void> _insert(BackupDocument doc) async {
    for (final r in doc.rows('projects')) {
      await db.into(db.projects).insert(ProjectRow.fromJson(databaseFields(r)));
    }
    for (final r in doc.rows('categories')) {
      await db
          .into(db.categories)
          .insert(CategoryRow.fromJson(databaseFields(r)));
    }
    for (final r in doc.rows('balanceRecords')) {
      await db
          .into(db.balanceRecords)
          .insert(BalanceRecordRow.fromJson(databaseFields(r)));
    }
    for (final r in doc.rows('projectEntries')) {
      await db
          .into(db.projectEntries)
          .insert(ProjectEntryRow.fromJson(databaseFields(r)));
    }
    for (final r in doc.rows('bills')) {
      await db.into(db.bills).insert(BillRow.fromJson(databaseFields(r)));
    }
    for (final r in doc.rows('memos')) {
      final m = databaseFields(r);
      m['tagsJson'] = jsonEncode(m.remove('tags'));
      await db.into(db.memos).insert(MemoRow.fromJson(m));
    }
    for (final r in doc.rows('editHistory')) {
      await db
          .into(db.editHistories)
          .insert(
            EditHistoryRow(
              id: r['id'] as String,
              entityType: r['entityType'] as String,
              entityId: r['entityId'] as String,
              changedAtMs: DateTime.parse(r['changedAt'] as String)
                  .millisecondsSinceEpoch,
              beforeJson: jsonEncode(r['before']),
              afterJson: jsonEncode(r['after']),
            ),
          );
    }
    final s = doc.data['settings'] as Map<String, dynamic>;
    await db
        .into(db.appPreferences)
        .insert(
          SettingsRow(
            id: 1,
            themeMode: s['themeMode'] as String,
            languageMode: s['languageMode'] as String,
            currency: s['currency'] as String,
            timeZone: s['timeZone'] as String,
          ),
        );
  }

  Future<void> reset(String deviceZone) => db.transaction(() async {
    await _clear();
    await finance.initialize(deviceZone);
    await db.delete(db.localDataStates).go();
    await _state(
      const LocalDataStatesCompanion(pendingCachePurge: Value(true)),
    );
  });
  Future<bool> get purgePending async =>
      (await db.select(db.localDataStates).getSingleOrNull())
          ?.pendingCachePurge ??
      false;
  Future<void> acknowledgePurge() => db.transaction(
    () =>
        _state(const LocalDataStatesCompanion(pendingCachePurge: Value(false))),
  );
}
