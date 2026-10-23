import 'dart:convert';

import 'package:crypto/crypto.dart';

const currentBackupFormatVersion = 2;

class BackupFailure implements Exception {
  const BackupFailure(this.code);
  final String code;
  @override
  String toString() => 'BackupFailure($code)';
}

Object? canonicalValue(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final k in keys) k: canonicalValue(value[k])};
  }
  if (value is List) return value.map(canonicalValue).toList();
  return value;
}

String canonicalJson(Object? value) => jsonEncode(canonicalValue(value));
Map<String, dynamic> signedBackup(Map<String, dynamic> unsigned) => {
  ...unsigned,
  'checksum': {
    'algorithm': 'SHA-256',
    'value': sha256.convert(utf8.encode(canonicalJson(unsigned))).toString(),
  },
};

class BackupEnvelope {
  const BackupEnvelope(
    this.root,
    this.sourceVersion,
    this.integrityVerified,
    this.converted,
  );
  final Map<String, dynamic> root;
  final int sourceVersion;
  final bool integrityVerified, converted;
}

typedef BackupMigrator = Map<String, dynamic> Function(Map<String, dynamic>);

// Add a tested N -> N+1 converter and frozen fixtures before increasing this
// version. appVersion and SQLite user_version never choose backup migrations.
final Map<int, BackupMigrator> _migrators = {
  0: (root) => {...root, 'schemaVersion': 1},
  1: (root) {
    final data = root['data'];
    final settings = data is Map<String, dynamic> ? data['settings'] : null;
    // v1 is a closed schema. Only this new non-financial preference defaults;
    // missing financial facts or unexpected legacy keys never get guessed.
    const keys = {'themeMode', 'languageMode', 'currency', 'timeZone'};
    if (settings is! Map<String, dynamic> ||
        settings.length != keys.length ||
        !keys.containsAll(settings.keys)) {
      throw const BackupFailure('invalidBackup');
    }
    return {
      ...root,
      'schemaVersion': 2,
      'data': {
        ...data as Map<String, dynamic>,
        'settings': {...settings, 'themeColor': 'blue'},
      },
    };
  },
};

BackupEnvelope normalizeBackupEnvelope(Map<String, dynamic> original) {
  Never fail(String code) => throw BackupFailure(code);
  if (original['format'] != 'finance-backup') fail('invalidBackup');
  final hasSchema = original.containsKey('schemaVersion');
  final hasAlias = original.containsKey('backupFormatVersion');
  final marker = hasSchema
      ? original['schemaVersion']
      : hasAlias
      ? original['backupFormatVersion']
      : 0;
  if (marker is! int || marker < 0) fail('backupVersion');
  if (hasAlias && original['backupFormatVersion'] is! int) {
    fail('backupVersion');
  }
  if (hasSchema && hasAlias && original['backupFormatVersion'] != marker) {
    fail('backupVersion');
  }
  if (marker > currentBackupFormatVersion) fail('backupFutureVersion');
  final expected = {
    'format',
    'appVersion',
    'exportedAt',
    'currency',
    'timeZone',
    'data',
    if (hasSchema) 'schemaVersion',
    if (hasAlias) 'backupFormatVersion',
    if (original.containsKey('checksum')) 'checksum',
  };
  if (original.length != expected.length ||
      !expected.containsAll(original.keys)) {
    fail('invalidBackup');
  }
  final hasChecksum = original.containsKey('checksum');
  // Historical project samples predated checksums. A missing checksum in a
  // modern, explicitly versioned file remains corruption, never a fallback.
  final preChecksumV1 =
      marker == 1 &&
      !hasChecksum &&
      original['appVersion'] is String &&
      RegExp(r'^0\.[1-3]\.0(\+\d+)?$')
          .hasMatch(original['appVersion'] as String);
  if (!hasChecksum && marker != 0 && !preChecksumV1) fail('backupChecksum');
  if (hasChecksum) {
    final check = original['checksum'];
    if (check is! Map<String, dynamic> ||
        check.length != 2 ||
        check['algorithm'] != 'SHA-256' ||
        check['value'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(check['value'] as String)) {
      fail('backupChecksum');
    }
    final unsigned = {...original}..remove('checksum');
    if (signedBackup(unsigned)['checksum']['value'] != check['value']) {
      fail('backupChecksum');
    }
  }
  var normalized = {...original}..remove('checksum');
  normalized.remove('backupFormatVersion');
  var version = marker;
  while (version < currentBackupFormatVersion) {
    final migrate = _migrators[version];
    if (migrate == null) fail('backupVersion');
    normalized = migrate(normalized);
    if (normalized['schemaVersion'] != version + 1) fail('backupVersion');
    version++;
  }
  normalized['schemaVersion'] = version;
  final converted = marker != version || hasAlias || !hasChecksum;
  return BackupEnvelope(
    converted ? signedBackup(normalized) : original,
    marker,
    hasChecksum,
    converted,
  );
}
