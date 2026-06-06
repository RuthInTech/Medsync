import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/education_content.dart';
import '../l10n/app_localizations.dart';
import '../models/education_module.dart';
import '../services/app_state.dart';
import '../theme.dart';

class EducationTab extends StatelessWidget {
  const EducationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final patient = app.patient!;
    final l = AppLocalizations(patient.language);
    final modules = EducationContent.forConditions(patient.conditions);
    final readCount = modules.where((m) => patient.readModuleIds.contains(m.id)).length;

    return Column(
      children: [
        _EducationHeader(readCount: readCount, total: modules.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              for (final m in modules) ...[
                _ModuleCard(
                  module: m,
                  language: patient.language,
                  read: patient.readModuleIds.contains(m.id),
                  minReadLabel: l.t('minRead'),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EducationHeader extends StatelessWidget {
  const _EducationHeader({required this.readCount, required this.total});
  final int readCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l = AppLocalizations(app.language);
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.t('learn'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '$readCount of $total articles read',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? readCount / total : 0,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _ModuleReader(module: module, language: language))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: read
              ? Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.3))
              : Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: module.condition.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.condition.icon,
                  color: module.condition.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: module.condition.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          module.condition.label,
                          style: TextStyle(
                              color: module.condition.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${module.readMinutes} $minReadLabel',
                        style: const TextStyle(
                            color: AppTheme.ink60, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (read)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: AppTheme.secondary, size: 16),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.ink60),
          ],
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
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(module.condition.label),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: module.condition.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              module.condition.label,
              style: TextStyle(
                  color: module.condition.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 16),
          Text(body,
              style: const TextStyle(
                  fontSize: 15.5, height: 1.6, color: AppTheme.ink)),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () async {
              await app.markModuleRead(module.id);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            icon: Icon(read ? Icons.check_circle : Icons.done_all, size: 18),
            label: Text(read ? l.t('readAgain') : l.t('markRead')),
            style: FilledButton.styleFrom(
              backgroundColor:
                  read ? AppTheme.secondary : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
