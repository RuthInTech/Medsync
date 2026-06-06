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

    return Column(
      children: [
        _GradientHeader(patient: patient, pending: pending, l: l),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              StreakBanner(stats: app.stats, language: patient.language),
              const SizedBox(height: 14),
              _RiskSummaryCard(),
              const SizedBox(height: 20),
              _ConditionStrip(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(l.t('today'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  const Spacer(),
                  if (doses.isNotEmpty)
                    Text(
                      '${doses.where((d) => d.status == DoseStatus.taken || d.status == DoseStatus.late).length}/${doses.length} done',
                      style: const TextStyle(
                          color: AppTheme.ink60, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (doses.isEmpty)
                _emptyState(l.t('noDosesToday'))
              else ...[
                if (pending.isEmpty)
                  _allDoneBanner(l.t('allDone')),
                for (final d in doses) _doseRow(context, app, d),
              ],
            ],
          ),
        ),
      ],
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
              backgroundColor: AppTheme.secondary,
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppTheme.ink60.withValues(alpha: 0.4), size: 48),
              const SizedBox(height: 12),
              Text(text,
                  style: const TextStyle(color: AppTheme.ink60, fontSize: 15)),
            ],
          ),
        ),
      );

  Widget _allDoneBanner(String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration_outlined,
                color: AppTheme.secondary, size: 20),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.secondary)),
          ],
        ),
      );
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.patient,
    required this.pending,
    required this.l,
  });

  final dynamic patient;
  final List pending;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final firstName = patient.name.split(' ').first as String;
    final initials = _initials(patient.name as String);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
      ),
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
                    Text(
                      'Hi, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pending.isEmpty
                          ? 'All done for today!'
                          : '${pending.length} dose${pending.length == 1 ? '' : 's'} remaining',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RiskDetailScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: risk.tier.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.insights_outlined, color: risk.tier.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.t('riskTitle'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    risk.factors.isNotEmpty ? risk.factors.first.label : '',
                    style: const TextStyle(
                        color: AppTheme.ink60, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RiskBadge(tier: risk.tier, score: risk.score),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.ink60, size: 20),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My conditions',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: conditions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = conditions[i];
              final count = app.patient!.medicationsFor(c).length;
              return Container(
                width: 116,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                      color: c.color.withValues(alpha: 0.15), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(c.icon, color: c.color, size: 18),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12.5)),
                        Text('$count med${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: AppTheme.ink60, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
