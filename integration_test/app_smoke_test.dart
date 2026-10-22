import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('The expected app screen did not appear within 30 seconds.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android launch, settings persistence, localization and back navigation',
    (tester) async {
      app.main();
      debugPrint('SMOKE: waiting for initialized home');
      await waitFor(tester, find.byKey(const Key('open-settings')));
      await tester.pumpAndSettle();
      debugPrint('SMOKE: initialized home visible');
      expect(find.text('¥0.00'), findsWidgets);
      await tester.tap(find.byKey(const Key('open-settings')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('language-en')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-en')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      debugPrint('SMOKE: dark appearance and English selected');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Finances'), findsOneWidget);
      expect(find.byKey(const Key('total-assets')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Dispose the app, then reopen its file to prove values reached disk.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final reopened = AppDatabase.open();
      final settings = await reopened
          .select(reopened.appPreferences)
          .getSingle();
      expect(settings.themeMode, 'dark');
      expect(settings.languageMode, 'en');
      expect(settings.currency, 'CNY');
      expect(await reopened.select(reopened.projects).get(), hasLength(9));
      expect(await reopened.select(reopened.bills).get(), isEmpty);
      await reopened.close();
      debugPrint('SMOKE: persisted settings and zero records checked');
    },
  );
}
