import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/risk_assessment.dart';
import '../services/app_state.dart';
import '../services/risk_engine.dart';
import '../theme.dart';
import '../widgets/risk_badge.dart';

class ClinicianTab extends StatelessWidget {
  const ClinicianTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l = AppLocalizations(app.language);
    const engine = RiskEngine();

    final assessed = SeedData.clinicRoster()
        .map((p) => (patient: p, risk: engine.assess(p.events)))
        .toList()
      ..sort((a, b) => b.risk.score.compareTo(a.risk.score));

    final flagged =
        assessed.where((e) => e.risk.tier == RiskTier.high).toList();

    return Column(
      children: [
        _ClinicianHeader(flaggedCount: flagged.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              if (flagged.isNotEmpty) ...[
                _SectionHeader(
                  label: l.t('flaggedPatients'),
                  count: flagged.length,
                  countColor: AppTheme.error,
                ),
                const SizedBox(height: 10),
                for (final e in flagged)
                  _PatientCard(
                    name: e.patient.name,
                    age: e.patient.age,
                    conditions: e.patient.conditions,
                    risk: e.risk,
                    highlighted: true,
                  ),
                const SizedBox(height: 20),
              ],
              _SectionHeader(
                label: l.t('allPatients'),
                count: assessed.length,
              ),
              const SizedBox(height: 10),
              for (final e in assessed)
                _PatientCard(
                  name: e.patient.name,
                  age: e.patient.age,
                  conditions: e.patient.conditions,
                  risk: e.risk,
                  highlighted: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClinicianHeader extends StatelessWidget {
  const _ClinicianHeader({required this.flaggedCount});
  final int flaggedCount;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clinic Dashboard',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      flaggedCount > 0
                          ? '$flaggedCount patient${flaggedCount == 1 ? '' : 's'} need attention'
                          : 'All patients in good standing',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_hospital_outlined,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Dr. Demo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count, this.countColor});
  final String label;
  final int count;
  final Color? countColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (countColor ?? AppTheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: countColor ?? AppTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.name,
    required this.age,
    required this.conditions,
    required this.risk,
    required this.highlighted,
  });

  final String name;
  final int age;
  final List<ConditionType> conditions;
  final RiskAssessment risk;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? AppTheme.error.withValues(alpha: 0.3)
        : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: risk.tier.color.withValues(alpha: 0.12),
          child: Text(
            name.characters.first.toUpperCase(),
            style: TextStyle(
                color: risk.tier.color,
                fontWeight: FontWeight.w800,
                fontSize: 16),
          ),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          '${age}y · ${conditions.map((c) => c.label).join(' · ')}',
          style: const TextStyle(fontSize: 12, color: AppTheme.ink60),
        ),
        trailing: RiskBadge(tier: risk.tier, score: risk.score),
        children: [
          const Divider(height: 16),
          for (final f in risk.factors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    f.weight > 0
                        ? Icons.trending_up
                        : f.weight < 0
                            ? Icons.trending_down
                            : Icons.remove,
                    size: 15,
                    color: f.weight > 0 ? AppTheme.error : AppTheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f.label,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          if (highlighted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Outreach logged for $name'),
                    backgroundColor: AppTheme.secondary,
                  ));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  minimumSize: const Size.fromHeight(40),
                ),
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Schedule outreach',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
