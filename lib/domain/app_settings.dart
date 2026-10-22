enum Appearance { system, light, dark }

enum AppLanguage {
  system('system'),
  simplifiedChinese('zh-Hans'),
  traditionalChinese('zh-Hant'),
  english('en');

  const AppLanguage(this.code);
  final String code;

  static AppLanguage fromCode(String code) =>
      values.firstWhere((item) => item.code == code);
}

final class AppSettings {
  const AppSettings({
    required this.appearance,
    required this.language,
    required this.timeZone,
  });

  final Appearance appearance;
  final AppLanguage language;
  final String timeZone;
}

final class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.type,
    required this.nameKey,
    required this.customName,
    required this.included,
    required this.amountMinor,
  });

  final String id;
  final String type;
  final String? nameKey;
  final String? customName;
  final bool included;
  final int amountMinor;
}
