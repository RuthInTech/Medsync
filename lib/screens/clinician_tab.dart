import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/risk_assessment.dart';
import '../services/app_state.dart';
import '../services/risk_engine.dart';
import '../widgets/risk_badge.dart';

/// Clinician-facing view: the provider's panel of patients, with high-risk
/// patients automatically flagged at the top for proactive outreach.
///
/// Each roster patient's risk is computed by the *same* [RiskEngine] the patient
/// app uses — the flag a clinician sees is the flag the model produced.
class ClinicianTab extends StatelessWidget {
  const ClinicianTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l = AppLocalizations(app.patient!.language);
    const engine = RiskEngine();

    final assessed = SeedData.clinicRoster()
        .map((p) => (patient: p, risk: engine.assess(p.events)))
        .toList()
      ..sort((a, b) => b.risk.score.compareTo(a.risk.score));

    final flagged =
        assessed.where((e) => e.risk.tier == RiskTier.high).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.t('clinic'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Chip(
                avatar: const Icon(Icons.medical_services_outlined, size: 18),
                label: const Text('Dr. demo'),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _flaggedHeader(context, flagged.length, l),
          const SizedBox(height: 12),
          if (flagged.isNotEmpty) ...[
            Text(l.t('flaggedPatients'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            for (final e in flagged)
              _PatientRow(
                  name: e.patient.name,
                  age: e.patient.age,
                  conditions: e.patient.conditions,
                  risk: e.risk,
                  highlighted: true),
            const SizedBox(height: 18),
          ],
          Text(l.t('allPatients'),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          for (final e in assessed)
            _PatientRow(
                name: e.patient.name,
                age: e.patient.age,
                conditions: e.patient.conditions,
                risk: e.risk,
                highlighted: false),
        ],
      ),
    );
  }

  Widget _flaggedHeader(
      BuildContext context, int count, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
            colors: [Color(0xFFD7263D), Color(0xFFA61B2B)]),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count patient${count == 1 ? '' : 's'} need attention',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const Text('Behavioral patterns suggest imminent non-adherence',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: risk.tier.color.withValues(alpha: 0.6))
            : Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: risk.tier.color.withValues(alpha: 0.15),
          child: Text('$age',
              style: TextStyle(
                  color: risk.tier.color, fontWeight: FontWeight.w700)),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(conditions.map((c) => c.label).join(' · '),
            style: const TextStyle(fontSize: 12.5)),
        trailing: RiskBadge(tier: risk.tier, score: risk.score),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final f in risk.factors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    f.weight > 0
                        ? Icons.trending_up
                        : (f.weight < 0
                            ? Icons.trending_down
                            : Icons.remove),
                    size: 16,
                    color: f.weight > 0
                        ? const Color(0xFFD7263D)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(f.label,
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          if (highlighted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Outreach logged for $name')));
                },
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Schedule outreach'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
