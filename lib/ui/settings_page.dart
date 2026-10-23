import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'data_management_page.dart';
import 'finance_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settings, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final settings = controller.settings!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    key: const Key('open-data-management'),
                    leading: const Icon(Icons.storage_outlined),
                    title: Text(strings.dataManagement),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DataManagementPage(controller: controller),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.appearanceAndLanguage,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.themeMode,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<Appearance>(
                          groupValue: settings.appearance,
                          onChanged: (value) {
                            if (value != null && !controller.saving) {
                              controller.setAppearance(value);
                            }
                          },
                          child: Column(
                            children: [
                              for (final appearance in Appearance.values)
                                RadioListTile<Appearance>(
                                  key: Key('theme-${appearance.name}'),
                                  title: Text(switch (appearance) {
                                    Appearance.system => strings.followSystem,
                                    Appearance.light => strings.light,
                                    Appearance.dark => strings.dark,
                                  }),
                                  value: appearance,
                                  contentPadding: EdgeInsets.zero,
                                  enabled: !controller.saving,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.themeColor,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            for (final color in ThemeColor.values)
                              ChoiceChip(
                                key: Key('accent-${color.name}'),
                                avatar: CircleAvatar(
                                  backgroundColor: themeSeed(color),
                                  radius: 8,
                                ),
                                label: Text(themeColorTitle(strings, color)),
                                selected: settings.themeColor == color,
                                onSelected: controller.saving
                                    ? null
                                    : (_) => controller.setThemeColor(color),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.language,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<AppLanguage>(
                          groupValue: settings.language,
                          onChanged: (value) {
                            if (value != null && !controller.saving) {
                              controller.setLanguage(value);
                            }
                          },
                          child: Column(
                            children: [
                              for (final language in AppLanguage.values)
                                RadioListTile<AppLanguage>(
                                  key: Key('language-${language.code}'),
                                  title: Text(switch (language) {
                                    AppLanguage.system => strings.followSystem,
                                    AppLanguage.simplifiedChinese => '简体中文',
                                    AppLanguage.traditionalChinese => '繁體中文',
                                    AppLanguage.english => 'English',
                                  }),
                                  value: language,
                                  contentPadding: EdgeInsets.zero,
                                  enabled: !controller.saving,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(strings.localData, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.localOnly,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text('${strings.currency}: CNY'),
                        const SizedBox(height: 8),
                        Text('${strings.timeZone}: ${settings.timeZone}'),
                      ],
                    ),
                  ),
                ),
                if (controller.hasSaveError) ...[
                  const SizedBox(height: 16),
                  Text(
                    strings.saveError,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
