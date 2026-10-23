import '../data/backup_repository.dart';
import '../domain/backup_document.dart';
import 'backup_files.dart';

import 'package:timezone/timezone.dart' as tz;

class ExportOutcome {
  const ExportOutcome(this.file, this.recentRecorded);
  final SavedBackup file;
  final bool recentRecorded;
}

class BackupManager {
  BackupManager(this.repository, this.files);
  final BackupRepository repository;
  final BackupFiles files;
  Future<ExportOutcome?> export(String prefix) async {
    final doc = await repository.capture();
    final time = DateTime.parse(doc.exportedAt);
    final local = tz.TZDateTime.from(
      time,
      tz.getLocation(doc.root['timeZone'] as String),
    );
    String two(int v) => v.toString().padLeft(2, '0');
    final name =
        '${prefix}_${local.year}-${two(local.month)}-${two(local.day)}_${two(local.hour)}${two(local.minute)}${two(local.second)}.moneybak';
    final saved = await files.save(doc.bytes, name);
    if (saved == null) return null;
    var recorded = true;
    try {
      await repository.recordExport(
        name: saved.name,
        uri: saved.uri,
        location: saved.location,
        bytes: saved.size,
        at: time,
      );
    } catch (_) {
      recorded = false;
    }
    return ExportOutcome(saved, recorded);
  }

  Future<BackupDocument?> pick() async {
    final bytes = await files.open();
    return bytes == null
        ? null
        : await parseBackup(bytes, repository.finance.clock());
  }

  Future<void> purgePending() async {
    if (await repository.purgePending) {
      try {
        await files.purge();
        await repository.acknowledgePurge();
      } catch (_) {
        throw const BackupFailure('cachePurge');
      }
    }
  }

  Future<void> reset(String deviceZone) async {
    await repository.reset(deviceZone);
    await purgePending();
  }
}
