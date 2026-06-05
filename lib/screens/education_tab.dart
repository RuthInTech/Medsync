import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/education_content.dart';
import '../l10n/app_localizations.dart';
import '../models/education_module.dart';
import '../services/app_state.dart';

/// Localized educational modules for the patient's conditions, with read state
/// feeding back into engagement tracking.
class EducationTab extends StatelessWidget {
  const EducationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final patient = app.patient!;
    final l = AppLocalizations(patient.language);
    final modules = EducationContent.forConditions(patient.conditions);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(l.t('learn'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(patient.language.label,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 14),
          for (final m in modules) ...[
            _ModuleCard(
              module: m,
              language: patient.language,
              read: patient.readModuleIds.contains(m.id),
              minReadLabel: l.t('minRead'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.language,
    required this.read,
    required this.minReadLabel,
  });

  final EducationModule module;
  final dynamic language;
  final bool read;
  final String minReadLabel;

  @override
  Widget build(BuildContext context) {
    final title = EducationContent.text(module.titleKey, language);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _ModuleReader(module: module, language: language))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: module.condition.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.condition.icon,
                    color: module.condition.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${module.condition.label} · ${module.readMinutes} $minReadLabel',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12.5)),
                  ],
                ),
              ),
              if (read)
                const Icon(Icons.check_circle, color: Color(0xFF2A9D8F))
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleReader extends StatelessWidget {
  const _ModuleReader({required this.module, required this.language});

  final EducationModule module;
  final dynamic language;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l = AppLocalizations(app.patient!.language);
    final title = EducationContent.text(module.titleKey, language);
    final body = EducationContent.text(module.bodyKey, language);
    final read = app.patient!.readModuleIds.contains(module.id);

    return Scaffold(
      appBar: AppBar(title: Text(module.condition.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text(body,
              style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () async {
              await app.markModuleRead(module.id);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            icon: Icon(read ? Icons.check : Icons.done_all),
            label: Text(read ? l.t('readAgain') : l.t('markRead')),
          ),
        ],
      ),
    );
  }
}
