import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../services/app_state.dart';

/// Profile + preferences: language selection (drives content localization),
/// reminder test, privacy note, and demo reset.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final patient = app.patient!;
    final l = AppLocalizations(patient.language);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(l.t('settings'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(patient.name),
              subtitle: Text(
                  '${patient.age} · ${patient.conditions.map((c) => c.label).join(', ')}'),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.t('language'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<AppLanguage>(
              groupValue: patient.language,
              onChanged: (v) {
                if (v != null) app.changeLanguage(v);
              },
              child: Column(
                children: [
                  for (final lang in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      value: lang,
                      title: Text(lang.label),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                app.notifications.isAvailable
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(l.t('testReminder')),
              subtitle: Text(app.notifications.isAvailable
                  ? 'Reminders fire on time, even offline'
                  : 'Notifications unavailable on this platform'),
              trailing: const Icon(Icons.send),
              onTap: () async {
                await app.notifications.showNow(
                  'Siyaphila',
                  'Time for your medication 💊',
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.t('reminderSent'))),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your health data is stored only on this device. Reports '
                    'are shared with a clinic only when you choose to.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, app),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset demo data'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppState app) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
            'This clears the patient profile and all dose history on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await app.reset();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
