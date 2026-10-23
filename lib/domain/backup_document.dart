import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/business_date.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../data/workspace.dart';
import 'backup_format.dart';
export 'backup_format.dart';

const backupAppVersion = '0.5.1+6';
const maxBackupBytes = 32 * 1024 * 1024;
const maxBackupRows = 100000;
const backupCollections = [
  'projects',
  'balanceRecords',
  'projectEntries',
  'bills',
  'categories',
  'memos',
  'editHistory',
];

Never _bad([String code = 'invalidBackup']) => throw BackupFailure(code);

class BackupDocument {
  BackupDocument._(
    this.root,
    this.bytes,
    this.sourceFormatVersion,
    this.integrityVerified,
    this.converted,
  );
  final Map<String, dynamic> root;
  final Uint8List bytes;
  final int sourceFormatVersion;
  final bool integrityVerified, converted;
  String get sourceVersionLabel =>
      sourceFormatVersion == 0 ? 'v0.0' : 'v$sourceFormatVersion';
  Map<String, dynamic> get data => root['data'] as Map<String, dynamic>;
  String get exportedAt => root['exportedAt'] as String;
  int count(String table) => (data[table] as List).length;
  String get identity => (root['checksum'] as Map)['value'] as String;
  int get assets => checkedSumMinor(
    _workspace().summaries
        .where((p) => p.type == 'asset' && p.included)
        .map((p) => p.amountMinor),
  );
  int get liabilities => checkedSumMinor(
    _workspace().summaries
        .where((p) => p.type == 'liability' && p.included)
        .map((p) => p.amountMinor),
  );
  Workspace _workspace() => Workspace(
    rows('projects')
        .map((r) => ProjectRow.fromJson(databaseFields(r)))
        .toList(),
    rows('balanceRecords')
        .map((r) => BalanceRecordRow.fromJson(databaseFields(r)))
        .toList(),
    rows('projectEntries')
        .map((r) => ProjectEntryRow.fromJson(databaseFields(r)))
        .toList(),
  );
  List<Map<String, dynamic>> rows(String table) =>
      (data[table] as List).cast<Map<String, dynamic>>();
  static BackupDocument decode(Uint8List bytes, {required DateTime now}) {
    if (bytes.length > maxBackupBytes) _bad('backupTooLarge');
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (decoded is! Map<String, dynamic>) _bad();
      final envelope = normalizeBackupEnvelope(decoded);
      final root = envelope.root;
      _keys(root, {
        'format',
        'schemaVersion',
        'appVersion',
        'exportedAt',
        'currency',
        'timeZone',
        'data',
        'checksum',
      });
      _text(root['appVersion'], 64, empty: false);
      _utc(root['exportedAt']);
      if (root['currency'] != 'CNY') _bad();
      final zone = _text(root['timeZone'], 100, empty: false);
      tz.getLocation(zone);
      final data = _map(root['data']);
      _keys(data, {...backupCollections, 'settings'});
      final settings = _map(data['settings']);
      _keys(settings, {
        'themeMode',
        'languageMode',
        'currency',
        'timeZone',
        'themeColor',
      });
      if (!{'system', 'light', 'dark'}.contains(settings['themeMode']) ||
          !{
            'red',
            'green',
            'purple',
            'blue',
          }.contains(settings['themeColor']) ||
          !{
            'system',
            'zh-Hans',
            'zh-Hant',
            'en',
          }.contains(settings['languageMode']) ||
          settings['currency'] != 'CNY' ||
          settings['timeZone'] != zone) {
        _bad();
      }
      final momentNow = BusinessMoment.inZone(now, zone);
      final today = momentNow.date;
      final ids = <String>{}, owners = <String, Set<String>>{};
      final tables = <String, List<Map<String, dynamic>>>{};
      var total = 0;
      for (final table in backupCollections) {
        if (data[table] is! List) _bad();
        final raw = data[table] as List;
        total += raw.length;
        if (total > maxBackupRows) _bad('backupTooLarge');
        final rows = raw.map(_map).toList();
        tables[table] = rows;
        owners[table] = <String>{};
        final orders = <int>{};
        for (final row in rows) {
          final id = _id(row['id']);
          if (!ids.add(id)) _bad();
          owners[table]!.add(id);
          _record(table, row, today, momentNow.time);
          if (table == 'projects' || table == 'categories') {
            if (!orders.add(row['sortOrder'] as int)) _bad();
          }
        }
      }
      final projects = {for (final p in tables['projects']!) p['id']: p};
      final categories = {for (final c in tables['categories']!) c['id']: c};
      final orderKeys = <String>{};
      for (final b in tables['balanceRecords']!) {
        final p = projects[b['projectId']];
        if (p == null ||
            !isBalanceType(p['type'] as String) ||
            !orderKeys.add('${b['projectId']}:${b['orderKey']}')) {
          _bad();
        }
      }
      for (final e in tables['projectEntries']!) {
        final p = projects[e['projectId']];
        if (p == null || isBalanceType(p['type'] as String)) _bad();
      }
      for (final b in tables['bills']!) {
        final c = categories[b['categoryId']];
        if (c == null || c['type'] != b['type']) _bad();
      }
      const ownerNames = {
        'project': 'projects',
        'balanceRecord': 'balanceRecords',
        'projectEntry': 'projectEntries',
        'bill': 'bills',
        'category': 'categories',
        'memo': 'memos',
      };
      for (final h in tables['editHistory']!) {
        final table = ownerNames[h['entityType']];
        if (table == null || !owners[table]!.contains(h['entityId'])) _bad();
        for (final key in ['before', 'after']) {
          final snapshot = _map(h[key]);
          if (snapshot.containsKey('id') && snapshot['id'] != h['entityId']) {
            _bad();
          }
          _historyValue(snapshot, 0);
        }
      }
      return BackupDocument._(
        root,
        envelope.converted
            ? Uint8List.fromList(utf8.encode(canonicalJson(root)))
            : Uint8List.fromList(bytes),
        envelope.sourceVersion,
        envelope.integrityVerified,
        envelope.converted,
      );
    } on BackupFailure {
      rethrow;
    } catch (_) {
      _bad();
    }
  }
}

Future<BackupDocument> parseBackup(Uint8List bytes, DateTime now) =>
    Isolate.run(() {
      tzdata.initializeTimeZones();
      return BackupDocument.decode(bytes, now: now);
    });
Map<String, dynamic> databaseFields(Map<String, dynamic> row) {
  final result = {...row};
  for (final field in ['createdAt', 'updatedAt']) {
    final value = result.remove(field);
    result['${field}Ms'] = DateTime.parse(value as String)
        .millisecondsSinceEpoch;
  }
  return result;
}

Map<String, dynamic> portableFields(Map<String, dynamic> row) {
  final result = {...row};
  for (final field in ['createdAt', 'updatedAt']) {
    final value = result.remove('${field}Ms');
    result[field] = DateTime.fromMillisecondsSinceEpoch(
      value as int,
      isUtc: true,
    ).toIso8601String();
  }
  return result;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : _bad();
void _keys(Map<String, dynamic> value, Set<String> keys) {
  if (value.length != keys.length || !keys.containsAll(value.keys)) _bad();
}

String _text(Object? value, int max, {bool empty = true}) {
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty)) {
    _bad();
  }
  return value;
}

String _id(Object? value) {
  final id = _text(value, 36, empty: false);
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(id)) {
    _bad();
  }
  return id;
}

int _integer(Object? value, {int min = 0, int max = 9223372036854775807}) {
  if (value is! int || value < min || value > max) _bad();
  return value;
}

void _utc(Object? value) {
  final s = _text(value, 30, empty: false);
  if (!RegExp(
    r'^\d{4}-\d{2}-\d{2}T([01]\d|2[0-3]):[0-5]\d:[0-5]\d(\.\d{1,3})?Z$',
  ).hasMatch(s)) {
    _bad();
  }
  BusinessDate.parse(s.substring(0, 10));
  DateTime.parse(s);
}

void _record(
  String table,
  Map<String, dynamic> r,
  BusinessDate today,
  String nowTime,
) {
  final common = {'id', 'createdAt', 'updatedAt'};
  const fields = {
    'projects': {
      'type',
      'nameKey',
      'customName',
      'categoryKey',
      'iconKey',
      'colorKey',
      'includeInSummary',
      'sortOrder',
      'note',
    },
    'balanceRecords': {
      'projectId',
      'balanceMinor',
      'businessDate',
      'businessTime',
      'orderKey',
      'note',
    },
    'projectEntries': {
      'projectId',
      'amountMinor',
      'businessDate',
      'businessTime',
      'note',
    },
    'bills': {
      'type',
      'amountMinor',
      'categoryId',
      'businessDate',
      'businessTime',
      'note',
    },
    'categories': {'type', 'nameKey', 'customName', 'sortOrder', 'isActive'},
    'memos': {'title', 'body', 'businessDate', 'tags'},
  };
  if (table == 'editHistory') {
    _keys(r, {'id', 'entityType', 'entityId', 'changedAt', 'before', 'after'});
    _text(r['entityType'], 30, empty: false);
    _id(r['entityId']);
    _utc(r['changedAt']);
    _map(r['before']);
    _map(r['after']);
    return;
  }
  _keys(r, {...common, ...fields[table]!});
  _utc(r['createdAt']);
  _utc(r['updatedAt']);
  if (r.containsKey('businessDate')) {
    final d = BusinessDate.parse(r['businessDate'] as String);
    if (d.compareTo(today) > 0) _bad();
    if (r.containsKey('businessTime')) {
      final moment = BusinessMoment(d, r['businessTime'] as String);
      if (moment.compareTo(BusinessMoment(today, nowTime)) > 0) _bad();
    }
  }
  if (r.containsKey('note')) _text(r['note'], 2000);
  if (table == 'projects' || table == 'categories') {
    for (final k in ['nameKey', 'customName']) {
      if (r[k] != null) _text(r[k], 80, empty: false);
    }
    if (r['nameKey'] == null && r['customName'] == null) _bad();
    _integer(r['sortOrder']);
  }
  switch (table) {
    case 'projects':
      if (!{
            'asset',
            'liability',
            'income_log',
            'expense_log',
          }.contains(r['type']) ||
          r['includeInSummary'] is! bool ||
          (!isBalanceType(r['type'] as String) &&
              r['includeInSummary'] != false)) {
        _bad();
      }
      final category = _text(r['categoryKey'], 87, empty: false);
      _text(
        category.startsWith('custom:') ? category.substring(7) : category,
        80,
        empty: false,
      );
      _text(r['iconKey'], 80, empty: false);
      _text(r['colorKey'], 80, empty: false);
    case 'balanceRecords':
      _id(r['projectId']);
      _integer(r['balanceMinor'], max: maxRecordMinor);
      _integer(r['orderKey']);
    case 'projectEntries':
      _id(r['projectId']);
      _integer(r['amountMinor'], min: 1, max: maxRecordMinor);
    case 'bills':
      _id(r['categoryId']);
      _integer(r['amountMinor'], min: 1, max: maxRecordMinor);
      if (!{'income', 'expense'}.contains(r['type'])) _bad();
    case 'categories':
      if (!{'income', 'expense'}.contains(r['type']) ||
          r['isActive'] is! bool) {
        _bad();
      }
    case 'memos':
      _text(r['title'], 200, empty: false);
      _text(r['body'], 20000);
      if (r['tags'] is! List) _bad();
      final tags = r['tags'] as List;
      if (tags.length > 10 || tags.toSet().length != tags.length) _bad();
      for (final tag in tags) {
        _text(tag, 30, empty: false);
      }
  }
}

void _historyValue(Object? value, int depth) {
  if (depth > 24) _bad();
  if (value is Map) {
    for (final e in value.entries) {
      _text(e.key, 100, empty: false);
      if (e.key == 'amountMinor') {
        _integer(e.value, min: 1, max: maxRecordMinor);
      }
      if (e.key == 'balanceMinor') _integer(e.value, max: maxRecordMinor);
      if (e.key == 'businessDate') BusinessDate.parse(e.value as String);
      if ({'createdAt', 'updatedAt'}.contains(e.key)) _utc(e.value);
      _historyValue(e.value, depth + 1);
    }
  } else if (value is List) {
    if (value.length > maxBackupRows) _bad();
    for (final v in value) {
      _historyValue(v, depth + 1);
    }
  } else if (value is String) {
    _text(value, 20000);
  } else if (value is int) {
    _integer(value, min: -9223372036854775808);
  } else if (value != null && value is! bool) {
    _bad();
  }
}
