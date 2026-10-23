import 'package:flutter/material.dart';

import '../domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/app_theme.dart';
import '../ui/home_page.dart';
import 'finance_controller.dart';

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    if (locale.languageCode == 'zh') {
      final traditional =
          locale.scriptCode == 'Hant' ||
          (locale.scriptCode != 'Hans' &&
              const {'TW', 'HK', 'MO'}.contains(locale.countryCode));
      return Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: traditional ? 'Hant' : 'Hans',
      );
    }
    if (locale.languageCode == 'en') return const Locale('en');
  }
  return const Locale('en');
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key, required this.controller});
  final FinanceController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final settings = controller.settings!;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
        theme: buildAppTheme(Brightness.light, settings.themeColor),
        darkTheme: buildAppTheme(Brightness.dark, settings.themeColor),
        themeMode: switch (settings.appearance) {
          Appearance.system => ThemeMode.system,
          Appearance.light => ThemeMode.light,
          Appearance.dark => ThemeMode.dark,
        },
        locale: switch (settings.language) {
          AppLanguage.system => null,
          AppLanguage.simplifiedChinese => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
          ),
          AppLanguage.traditionalChinese => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
          ),
          AppLanguage.english => const Locale('en'),
        },
        localeListResolutionCallback: resolveAppLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(top: false, child: child ?? const SizedBox.shrink()),
        ),
        home: HomePage(controller: controller),
      );
    },
  );
}
