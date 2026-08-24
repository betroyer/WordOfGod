import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (modes) {
                ref.read(settingsProvider.notifier).update(
                      settings.copyWith(themeMode: modes.first),
                    );
              },
            ),
          ),
          const _Header('Bible reading'),
          ListTile(
            title: const Text('Font size'),
            subtitle: Slider(
              min: 14,
              max: 32,
              divisions: 18,
              value: settings.fontSize,
              label: settings.fontSize.toStringAsFixed(0),
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(fontSize: v)),
            ),
          ),
          ListTile(
            title: const Text('Line spacing'),
            subtitle: Slider(
              min: 1.3,
              max: 2.2,
              divisions: 9,
              value: settings.lineSpacing,
              label: settings.lineSpacing.toStringAsFixed(1),
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(lineSpacing: v)),
            ),
          ),
          const _Header('Notifications'),
          SwitchListTile(
            title: const Text('Daily Bible reminder'),
            value: settings.notificationsEnabled,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(notificationsEnabled: v)),
          ),
          ListTile(
            title: const Text('Reminder time'),
            subtitle: Text(settings.reminderTime.format(context)),
            enabled: settings.notificationsEnabled,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: settings.reminderTime,
              );
              if (time != null) {
                await ref.read(settingsProvider.notifier).update(
                      settings.copyWith(
                        reminderHour: time.hour,
                        reminderMinute: time.minute,
                      ),
                    );
              }
            },
          ),
          SwitchListTile(
            title: const Text('Repeat daily'),
            subtitle: const Text('Off uses a weekly reminder at this time'),
            value: settings.reminderDaily,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(reminderDaily: v)),
          ),
          const _Header('AI Assistant (requires internet)'),
          SwitchListTile(
            title: const Text('Enable AI'),
            subtitle: const Text(
              'Uses the internet to explain verses and answer Bible questions',
            ),
            value: settings.aiEnabled,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(aiEnabled: v)),
          ),
          ListTile(
            title: const Text('API key'),
            subtitle: Text(
              settings.effectiveAiApiKey.isEmpty
                  ? 'Required — paste your OpenAI-compatible key'
                  : '•••••••• ready for online requests',
            ),
            onTap: () => _editText(
              context,
              title: 'AI API key',
              value: settings.aiApiKey,
              onSave: (v) => ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(aiApiKey: v)),
            ),
          ),
          ListTile(
            title: const Text('API base URL'),
            subtitle: Text(settings.aiBaseUrl),
            onTap: () => _editText(
              context,
              title: 'API base URL',
              value: settings.aiBaseUrl,
              onSave: (v) => ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(aiBaseUrl: v)),
            ),
          ),
          ListTile(
            title: const Text('Model'),
            subtitle: Text(settings.aiModel),
            onTap: () => _editText(
              context,
              title: 'Model',
              value: settings.aiModel,
              onSave: (v) => ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(aiModel: v)),
            ),
          ),
          ListTile(
            title: const Text('Clear AI history'),
            onTap: () async {
              await ref.read(aiRepositoryProvider).clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI conversations deleted')),
                );
              }
            },
          ),
          const _Header('Data'),
          ListTile(
            title: const Text('Export local data'),
            onTap: () => _export(ref, context),
          ),
          ListTile(
            title: const Text('Import local data'),
            onTap: () => _import(ref, context),
          ),
          ListTile(
            title: const Text('Reset local data'),
            subtitle: const Text('Keeps the Bible text; clears journals and progress'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset local data?'),
                  content: const Text(
                    'This deletes notes, journals, highlights, and progress on this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(databaseProvider).resetUserData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local user data reset')),
                  );
                }
              }
            },
          ),
          const _Header('About'),
          const ListTile(
            title: Text(AppConstants.appName),
            subtitle: Text(
              '${AppConstants.tagline}\nTranslation: ${AppConstants.translation}',
            ),
            isThreeLine: true,
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text(AppConstants.privacyNote),
            isThreeLine: true,
          ),
          const ListTile(
            title: Text('License / copyright'),
            subtitle: Text(AppConstants.copyrightNote),
            isThreeLine: true,
          ),
          const ListTile(
            title: Text('AI disclaimer'),
            subtitle: Text(AppConstants.aiDisclaimer),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String value,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: value);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next != null) await onSave(next);
  }

  Future<void> _export(WidgetRef ref, BuildContext context) async {
    final db = ref.read(databaseProvider);
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': [
        for (final n in await db.select(db.notes).get())
          {'verseId': n.verseId, 'body': n.body},
      ],
      'bookmarks': [
        for (final n in await db.select(db.bookmarks).get())
          {'verseId': n.verseId, 'note': n.note},
      ],
      'favorites': [
        for (final n in await db.select(db.favorites).get()) {'verseId': n.verseId},
      ],
      'highlights': [
        for (final n in await db.select(db.highlights).get())
          {'verseId': n.verseId, 'category': n.category},
      ],
      'reflections': [
        for (final n in await db.select(db.reflections).get())
          {
            'read': n.read,
            'learned': n.learned,
            'spoke': n.spoke,
            'apply': n.apply,
            'pray': n.pray,
          },
      ],
      'prayers': [
        for (final n in await db.select(db.prayers).get())
          {
            'title': n.title,
            'body': n.body,
            'category': n.category,
            'status': n.status,
          },
      ],
      'devotionals': [
        for (final n in await db.select(db.devotionalEntries).get())
          {
            'date': n.date.toIso8601String(),
            'reference': n.reference,
            'title': n.title,
            'reflection': n.reflection,
            'application': n.application,
            'prayer': n.prayer,
          },
      ],
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/faithpath-export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'FaithPath export'),
    );
  }

  Future<void> _import(WidgetRef ref, BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected $path. Import of records is best done after a reset.')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
