import 'dart:convert';
import 'dart:io';

import 'package:finance_app/domain/backup_format.dart';

Future<void> main() async {
  final raw = await File('test/fixtures/backups/v1-stage4-all-types.json')
      .readAsString();
  final root = jsonDecode(raw) as Map<String, dynamic>;
  root.remove('checksum');
  root['schemaVersion'] = currentBackupFormatVersion + 1;
  await File('artifacts/verification/stage5-future.moneybak')
      .writeAsString(canonicalJson(signedBackup(root)));
  await File('test/fixtures/backups/v0.0-all-types.json')
      .copy('artifacts/verification/stage5-v0.moneybak');
  await File('test/fixtures/backups/v1-stage4-all-types.json')
      .copy('artifacts/verification/stage5-v1.moneybak');
  stdout.writeln('QA v0.0, frozen v1 and future-version files prepared.');
}
