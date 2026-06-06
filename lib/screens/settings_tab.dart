import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/patient.dart';
import '../main.dart';
import '../services/app_state.dart';
import '../theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final patient = app.patient!;
    final l = AppLocalizations(patient.language);

    return Column(
      children: [
        _SettingsHeader(patient: patient),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _SectionLabel('Language'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: AppLanguage.values.map((lang) {
                    final selected = patient.language == lang;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(lang.label,
                          style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      trailing: selected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.secondary)
                          : null,
                      onTap: () => app.changeLanguage(lang),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Notifications'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      app.notifications.isAvailable
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(l.t('testReminder'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    app.notifications.isAvailable
                        ? 'Reminders fire on time, even offline'
                        : 'Notifications unavailable on this platform',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  trailing: const Icon(Icons.send_outlined,
                      color: AppTheme.primary, size: 18),
                  onTap: () async {
                    await app.notifications.showNow(
                      'Siyaphila',
                      'Time for your medication',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.t('reminderSent'))),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Data & Privacy'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppTheme.secondary, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your health data is stored on this device. Reports are shared with a clinic only when you choose to.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Account'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restart_alt,
                            color: Color(0xFF92400E), size: 20),
                      ),
                      title: const Text('Reset demo data',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      onTap: () => _confirmReset(context, app),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_outlined,
                            color: AppTheme.error, size: 20),
                      ),
                      title: Text(l.t('logout'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.error)),
                      onTap: () => _confirmLogout(context, app, l),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppState app, AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('logout')),
        content: Text(l.t('logoutConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              MedisyncApp.of(context).onLogout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(l.t('logout')),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.patient});
  final PatientProfile patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  patient.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${patient.age}y · ${patient.conditions.map((c) => c.label).join(', ')}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppTheme.ink60,
          letterSpacing: 0.4),
    );
  }
}
