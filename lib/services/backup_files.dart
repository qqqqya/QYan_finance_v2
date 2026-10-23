import 'package:flutter/services.dart';

import '../domain/backup_document.dart';

class SavedBackup {
  const SavedBackup(this.name, this.uri, this.location, this.size);
  final String name, uri, location;
  final int size;
}

abstract class BackupFiles {
  Future<SavedBackup?> save(Uint8List bytes, String name);
  Future<Uint8List?> open();
  Future<void> share(String uri, String name);
  Future<void> purge();
}

class AndroidBackupFiles implements BackupFiles {
  static const channel = MethodChannel('finance/backup');
  @override
  Future<SavedBackup?> save(Uint8List bytes, String name) async {
    final result = await channel.invokeMapMethod<String, dynamic>('save', {
      'bytes': bytes,
      'name': name,
    });
    if (result == null) return null;
    return SavedBackup(
      result['name'] as String,
      result['uri'] as String,
      result['location'] as String,
      result['size'] as int,
    );
  }

  @override
  Future<Uint8List?> open() =>
      channel.invokeMethod<Uint8List>('open', {'maxBytes': maxBackupBytes});
  @override
  Future<void> share(String uri, String name) =>
      channel.invokeMethod<void>('share', {'uri': uri, 'name': name});
  @override
  Future<void> purge() => channel.invokeMethod<void>('purge');
}
