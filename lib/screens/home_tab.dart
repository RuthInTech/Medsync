import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/dose_event.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/dose_card.dart';
import '../widgets/risk_badge.dart';
import '../widgets/streak_banner.dart';
import 'proof_of_dose_sheet.dart';
import 'risk_detail_screen.dart';

/// The patient's daily home: gamification hero, risk summary, condition chips,
/// and today's dose list with Proof-of-Dose actions.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final patient = app.patient!;
    final l = AppLocalizations(patient.language);
    final doses = app.todaysDoses();
    final pending = doses
        .where((d) =>
            d.status == DoseStatus.due || d.status == DoseStatus.upcoming)
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(patient.name),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(l.t('tagline'),
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(_initials(patient.name),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StreakBanner(stats: app.stats, language: patient.language),
          const SizedBox(height: 14),
          _RiskSummaryCard(),
          const SizedBox(height: 18),
          _ConditionStrip(),
          const SizedBox(height: 18),
          Text(l.t('today'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          if (doses.isEmpty)
            _emptyState(l.t('noDosesToday'))
          else ...[
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Color(0xFF2A9D8F)),
                    const SizedBox(width: 8),
                    Text(l.t('allDone'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A9D8F))),
                  ],
                ),
              ),
            for (final d in doses) _doseRow(context, app, d),
          ],
        ],
      ),
    );
  }

  Widget _doseRow(BuildContext context, AppState app, DoseEvent dose) {
    final med = app.medicationById(dose.medicationId);
    if (med == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DoseCard(
        event: dose,
        medication: med,
        onTake: () async {
          final method = await showProofOfDose(
            context,
            medication: med,
            language: app.patient!.language,
          );
          if (method == null) return;
          await app.confirmDose(dose, method);
          if (!context.mounted) return;
          final l = AppLocalizations(app.patient!.language);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.t('doseConfirmed')),
              backgroundColor: const Color(0xFF2A9D8F),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
            child: Text(text, style: TextStyle(color: Colors.grey.shade600))),
      );

  String _greeting(String name) => 'Hi, ${name.split(' ').first} 👋';

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _RiskSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final risk = app.risk;
    final l = AppLocalizations(app.patient!.language);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const RiskDetailScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.insights, color: risk.tier.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.t('riskTitle'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      risk.factors.first.label,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              RiskBadge(tier: risk.tier, score: risk.score),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final conditions = app.patient!.conditions;
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: conditions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = conditions[i];
          final count = app.patient!.medicationsFor(c).length;
          return Container(
            width: 124,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: c.color.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(c.icon, color: c.color, size: 20),
                ),
                Text(c.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$count med${count == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
