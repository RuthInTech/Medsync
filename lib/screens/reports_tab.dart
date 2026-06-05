import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/report_service.dart';
import '../widgets/adherence_chart.dart';
import '../widgets/risk_badge.dart';

/// Generates a shareable adherence summary the patient can hand to their doctor.
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final patient = app.patient!;
    final stats = app.stats;
    final risk = app.risk;
    final l = AppLocalizations(patient.language);
    final summary = const ReportService().buildSummary(
      patient: patient,
      events: app.events,
      stats: stats,
      risk: risk,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(l.t('report'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('${stats.completionPercent}%', l.t('completion')),
                      _stat('${stats.currentStreak}', l.t('streak')),
                      _stat('${stats.missedCount}', 'missed'),
                    ],
                  ),
                  const Divider(height: 28),
                  AdherenceChart(weeklyRates: stats.weeklyRates),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Risk: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      RiskBadge(tier: risk.tier, score: risk.score),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preview',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101418),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      summary,
                      style: const TextStyle(
                        color: Color(0xFFB8F2E6),
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: summary));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.t('reportCopied'))),
              );
            },
            icon: const Icon(Icons.share),
            label: Text(l.t('shareReport')),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
}
