import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app/finance_app.dart';
import 'app/finance_controller.dart';
import 'data/app_database.dart';
import 'data/finance_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  runApp(const FinanceBootstrap());
}

class FinanceBootstrap extends StatefulWidget {
  const FinanceBootstrap({super.key});

  @override
  State<FinanceBootstrap> createState() => _FinanceBootstrapState();
}

class _FinanceBootstrapState extends State<FinanceBootstrap> {
  late Future<FinanceController> _startup = _open();
  AppDatabase? _database;
  FinanceController? _controller;

  Future<FinanceController> _open() async {
    final database = AppDatabase.open();
    _database = database;
    FinanceController? controller;
    try {
      final existing = await database
          .select(database.appPreferences)
          .getSingleOrNull();
      final zone =
          existing?.timeZone ??
          (await FlutterTimezone.getLocalTimezone()).identifier;
      final repository = FinanceRepository(database);
      await repository.initialize(zone);
      controller = FinanceController(repository);
      await controller.start();
      _controller = controller;
      return controller;
    } catch (error, stack) {
      if (kDebugMode) debugPrint('Finance startup failed: $error\n$stack');
      controller?.dispose();
      await database.close();
      _database = null;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FinanceController>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.hasData) return FinanceApp(controller: snapshot.requireData);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: resolveAppLocale,
        home: Builder(
          builder: (context) {
            final strings = AppLocalizations.of(context)!;
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: snapshot.hasError
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(strings.startupError),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => setState(() {
                                  _startup = _open();
                                }),
                                child: Text(strings.retry),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  @override
  void dispose() {
    _controller?.dispose();
    unawaited(_database?.close());
    super.dispose();
  }
}
