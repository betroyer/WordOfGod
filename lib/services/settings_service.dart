import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/secrets/ai_secrets.dart';

class AppSettings {
  AppSettings({
    required this.themeMode,
    required this.fontSize,
    required this.lineSpacing,
    required this.notificationsEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderDaily,
    required this.aiEnabled,
    required this.aiApiKey,
    required this.aiBaseUrl,
    required this.aiModel,
    required this.lastBookId,
    required this.lastChapter,
  });

  final ThemeMode themeMode;
  final double fontSize;
  final double lineSpacing;
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool reminderDaily;
  final bool aiEnabled;
  final String aiApiKey;
  final String aiBaseUrl;
  final String aiModel;
  final int? lastBookId;
  final int? lastChapter;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  /// Prefers Settings → local secrets → `--dart-define=FAITHPATH_AI_API_KEY`.
  String get effectiveAiApiKey {
    final saved = aiApiKey.trim();
    if (saved.isNotEmpty) return saved;
    if (AiSecrets.apiKey.trim().isNotEmpty) return AiSecrets.apiKey.trim();
    const fromEnv = String.fromEnvironment('FAITHPATH_AI_API_KEY');
    return fromEnv.trim();
  }

  bool get isAiReady => aiEnabled && effectiveAiApiKey.isNotEmpty;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    double? lineSpacing,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? reminderDaily,
    bool? aiEnabled,
    String? aiApiKey,
    String? aiBaseUrl,
    String? aiModel,
    int? lastBookId,
    int? lastChapter,
    bool clearLast = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderDaily: reminderDaily ?? this.reminderDaily,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      lastBookId: clearLast ? lastBookId : (lastBookId ?? this.lastBookId),
      lastChapter: clearLast ? lastChapter : (lastChapter ?? this.lastChapter),
    );
  }
}

class SettingsService {
  SettingsService(this._prefs);
  final SharedPreferences _prefs;

  static const _theme = 'themeMode';
  static const _font = 'fontSize';
  static const _spacing = 'lineSpacing';
  static const _notify = 'notifications';
  static const _hour = 'reminderHour';
  static const _minute = 'reminderMinute';
  static const _daily = 'reminderDaily';
  static const _ai = 'aiEnabled';
  static const _key = 'aiApiKey';
  static const _url = 'aiBaseUrl';
  static const _model = 'aiModel';
  static const _book = 'lastBookId';
  static const _chapter = 'lastChapter';

  AppSettings load() {
    final themeName = _prefs.getString(_theme) ?? 'system';
    final savedKey = _prefs.getString(_key) ?? '';
    final resolvedKey =
        savedKey.trim().isNotEmpty ? savedKey : AiSecrets.apiKey.trim();

    // Seed SharedPreferences once so Settings shows the key as configured.
    if (savedKey.trim().isEmpty && resolvedKey.isNotEmpty) {
      _prefs.setString(_key, resolvedKey);
    }
    if (!_prefs.containsKey(_ai)) {
      _prefs.setBool(_ai, true);
    }

    return AppSettings(
      themeMode: switch (themeName) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      fontSize: _prefs.getDouble(_font) ?? 18,
      lineSpacing: _prefs.getDouble(_spacing) ?? 1.6,
      notificationsEnabled: _prefs.getBool(_notify) ?? false,
      reminderHour: _prefs.getInt(_hour) ?? 7,
      reminderMinute: _prefs.getInt(_minute) ?? 0,
      reminderDaily: _prefs.getBool(_daily) ?? true,
      aiEnabled: _prefs.getBool(_ai) ?? true,
      aiApiKey: resolvedKey,
      aiBaseUrl: _prefs.getString(_url) ?? 'https://api.openai.com/v1',
      aiModel: _prefs.getString(_model) ?? 'gpt-4o-mini',
      lastBookId: _prefs.getInt(_book),
      lastChapter: _prefs.getInt(_chapter),
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(
      _theme,
      switch (s.themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
    await _prefs.setDouble(_font, s.fontSize);
    await _prefs.setDouble(_spacing, s.lineSpacing);
    await _prefs.setBool(_notify, s.notificationsEnabled);
    await _prefs.setInt(_hour, s.reminderHour);
    await _prefs.setInt(_minute, s.reminderMinute);
    await _prefs.setBool(_daily, s.reminderDaily);
    await _prefs.setBool(_ai, s.aiEnabled);
    await _prefs.setString(_key, s.aiApiKey);
    await _prefs.setString(_url, s.aiBaseUrl);
    await _prefs.setString(_model, s.aiModel);
    if (s.lastBookId != null) {
      await _prefs.setInt(_book, s.lastBookId!);
    }
    if (s.lastChapter != null) {
      await _prefs.setInt(_chapter, s.lastChapter!);
    }
  }
}
