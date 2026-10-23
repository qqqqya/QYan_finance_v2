import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../app/finance_controller.dart';
import '../data/backup_repository.dart';
import '../domain/backup_document.dart';
import '../l10n/app_localizations.dart';
import '../services/backup_files.dart';
import '../services/backup_manager.dart';
import 'finance_widgets.dart';

const backupGreen = Color(0xFF008C64);
String backupErrorText(AppLocalizations s, Object error) {
  final code = error is BackupFailure
      ? error.code
      : error is PlatformException
      ? error.code
      : 'restoreError';
  return switch (code) {
    'invalidBackup' => s.invalidBackup,
    'backupVersion' => s.backupVersionError,
    'backupChecksum' => s.backupChecksumError,
    'backupTooLarge' => s.backupLimitError,
    'fileWrite' => s.fileWriteError,
    'fileRead' => s.fileReadError,
    'fileShare' => s.fileShareError,
    'filePermission' => s.filePermissionError,
    'noSpace' => s.noSpaceError,
    'cachePurge' => s.cachePurgeError,
    _ => s.restoreError,
  };
}

String backupSize(int bytes) => bytes < 1024
    ? '$bytes B'
    : bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key, required this.controller, this.manager});
  final FinanceController controller;
  final BackupManager? manager;
  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  late final manager =
      widget.manager ??
      BackupManager(
        BackupRepository(widget.controller.repository),
        AndroidBackupFiles(),
      );
  late final stream = manager.repository.watchStatus();
  bool busy = false;
  AppLocalizations get s => AppLocalizations.of(context)!;
  Future<void> error(Object value) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          size: 44,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(s.backupError),
        content: Text(backupErrorText(s, value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.done),
          ),
        ],
      ),
    );
  }

  void cancelled() {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.backupCancelled)));
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      await error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> success(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.check_circle_outline,
        size: 52,
        color: backupGreen,
      ),
      title: Text(title),
      content: Text(body),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.done),
        ),
      ],
    ),
  );
  Future<void> share(String uri, String name) async {
    try {
      await manager.files.share(uri, name);
    } catch (e) {
      await error(e);
    }
  }

  Future<bool> export() async {
    final outcome = await manager.export(s.backupFilePrefix);
    if (!mounted) return false;
    if (outcome == null) {
      cancelled();
      return false;
    }
    final f = outcome.file;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backupGreen.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: backupGreen,
            size: 48,
          ),
        ),
        title: Text(s.backupSuccess),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.backupSuccessBody),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.backupFileName),
                      SelectableText(f.name),
                      const SizedBox(height: 12),
                      Text('${s.backupFileSize}: ${backupSize(f.size)}'),
                      const SizedBox(height: 12),
                      Text('${s.backupLocation}: ${f.location}'),
                    ],
                  ),
                ),
              ),
              if (!outcome.recentRecorded) Text(s.recentRecordError),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            key: const Key('share-export'),
            onPressed: () => share(f.uri, f.name),
            icon: const Icon(Icons.share_outlined),
            label: Text(s.shareBackup),
          ),
          FilledButton(
            key: const Key('finish-export'),
            onPressed: () => Navigator.pop(context),
            child: Text(s.done),
          ),
        ],
      ),
    );
    return true;
  }

  Future<void> preview(BackupDocument doc) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.backupPreview),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.backupDate}: ${doc.exportedAt}'),
              const SizedBox(height: 12),
              Text('${s.backupBills}: ${doc.count('bills')}'),
              Text(
                '${s.backupAccounts}: ${doc.rows('projects').where((p) => p['type'] == 'asset' || p['type'] == 'liability').length}',
              ),
              Text('${s.backupProjects}: ${doc.count('projects')}'),
              Text(
                '${s.records}: ${doc.count('balanceRecords') + doc.count('projectEntries')}',
              ),
              Text('${s.categories}: ${doc.count('categories')}'),
              Text('${s.memos}: ${doc.count('memos')}'),
              Text('${s.history}: ${doc.count('editHistory')}'),
              const SizedBox(height: 12),
              Text(s.totalAssets),
              MoneyText(doc.assets, size: 20),
              Text(s.totalLiabilities),
              MoneyText(doc.liabilities, size: 20),
              Text(
                '${s.themeMode}: ${_themeName(doc.data['settings']['themeMode'] as String)}',
              ),
              Text(
                '${s.language}: ${_languageName(doc.data['settings']['languageMode'] as String)}',
              ),
              const SizedBox(height: 16),
              Text(s.backupReplaceWarning),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            key: const Key('confirm-restore'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.confirmRestore),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await manager.repository.restore(doc);
    await widget.controller.refreshAfterRestore();
    // Rebuild inherited localization/theme before composing the result dialog.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await success(s.restoreSuccess, s.restoreSuccessBody);
  }

  String _themeName(String value) => switch (value) {
    'light' => s.light,
    'dark' => s.dark,
    _ => s.followSystem,
  };
  String _languageName(String value) => switch (value) {
    'zh-Hans' => '简体中文',
    'zh-Hant' => '繁體中文',
    'en' => 'English',
    _ => s.followSystem,
  };
  Future<void> reset({bool offerExport = true}) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.restart_alt,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(s.factoryReset),
        content: Text(s.factoryResetWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          if (offerExport)
            TextButton(
              onPressed: () => Navigator.pop(context, 'export'),
              child: Text(s.exportFirst),
            ),
          FilledButton(
            key: const Key('confirm-reset'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, 'reset'),
            child: Text(s.confirmReset),
          ),
        ],
      ),
    );
    if (action == 'export') {
      if (await export() && mounted) await reset(offerExport: false);
      return;
    }
    if (action != 'reset') return;
    final zone = (await FlutterTimezone.getLocalTimezone()).identifier;
    try {
      await manager.reset(zone);
    } finally {
      await widget.controller.refreshAfterRestore();
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await success(s.resetSuccess, s.resetSuccessBody);
  }

  Widget actionCard(
    String title,
    String hint,
    IconData icon,
    Key key,
    Future<void> Function() action, {
    bool green = false,
  }) => Card(
    color: green ? backupGreen.withValues(alpha: .10) : null,
    child: ListTile(
      key: key,
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon, color: green ? backupGreen : null, size: 30),
      title: Text(title),
      subtitle: Text(hint),
      trailing: const Icon(Icons.chevron_right),
      enabled: !busy,
      onTap: () => run(action),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: Text(s.dataManagement)),
      body: StreamBuilder<BackupStatus>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(s.dataError));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final status = snapshot.data!, local = status.local;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(s.backupIntro),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storage_outlined,
                            color: backupGreen,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.currentData,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('${s.backupBills}: ${status.bills}'),
                      Text('${s.backupAccounts}: ${status.accounts}'),
                      Text('${s.backupProjects}: ${status.projects}'),
                      Text('${s.memos}: ${status.memos}'),
                      Text('${s.lastBill}: ${status.latestBill ?? '—'}'),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: backupGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.localSaved)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (busy)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TickerMode(
                    enabled: ModalRoute.of(context)?.isCurrent ?? true,
                    child: const LinearProgressIndicator(),
                  ),
                ),
              actionCard(
                s.backupExport,
                s.backupExportHint,
                Icons.upload_file_outlined,
                const Key('export-backup'),
                () async {
                  await export();
                },
                green: true,
              ),
              actionCard(
                s.backupImport,
                s.backupImportHint,
                Icons.file_download_outlined,
                const Key('import-backup'),
                () async {
                  final doc = await manager.pick();
                  if (doc == null) {
                    cancelled();
                    return;
                  }
                  await preview(doc);
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.recentBackup,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (local?.lastExportName == null)
                        Text(s.noBackup)
                      else ...[
                        Text(
                          DateTime.fromMillisecondsSinceEpoch(
                            local!.lastExportAtMs!,
                            isUtc: true,
                          ).toLocal().toString(),
                        ),
                        SelectableText(local.lastExportName!),
                        Text(backupSize(local.lastExportBytes!)),
                        Text(local.lastExportLocation ?? ''),
                        TextButton.icon(
                          key: const Key('share-recent-backup'),
                          onPressed: busy
                              ? null
                              : () => run(
                                  () => share(
                                    local.lastExportUri!,
                                    local.lastExportName!,
                                  ),
                                ),
                          icon: const Icon(Icons.share_outlined),
                          label: Text(s.shareBackup),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.recoveryCopy,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(s.recoveryCopyHint),
                      const SizedBox(height: 8),
                      if (!status.hasRecovery)
                        Text(s.noRecoveryCopy)
                      else ...[
                        TextButton(
                          key: const Key('restore-private-copy'),
                          onPressed: busy
                              ? null
                              : () => run(() async {
                                  final doc = await manager.repository
                                      .recovery();
                                  if (doc == null) {
                                    throw const BackupFailure('invalidBackup');
                                  }
                                  await preview(doc);
                                }),
                          child: Text(s.restoreCopy),
                        ),
                        TextButton(
                          key: const Key('delete-private-copy'),
                          onPressed: busy
                              ? null
                              : () => run(() async {
                                  if (await confirmChange(
                                    context,
                                    s.deleteCopy,
                                    s.deleteCopyWarning,
                                  )) {
                                    await manager.repository.deleteRecovery();
                                  }
                                }),
                          child: Text(s.deleteCopy),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (local?.pendingCachePurge == true) ...[
                Text(s.cachePurgeError),
                OutlinedButton(
                  onPressed: busy ? null : () => run(manager.purgePending),
                  child: Text(s.purgeCache),
                ),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s.backupSafety),
                ),
              ),
              Text(
                s.backupCountsHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('factory-reset'),
                onPressed: busy ? null : () => run(reset),
                icon: const Icon(Icons.restart_alt),
                label: Text(s.factoryReset),
              ),
            ],
          );
        },
      ),
    ),
  );
}
