import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/adherence_chart.dart';
import '../widgets/risk_badge.dart';

class RiskDetailScreen extends StatelessWidget {
  const RiskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final risk = app.risk;
    final stats = app.stats;
    final l = AppLocalizations(app.patient!.language);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l.t('riskTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: CircularProgressIndicator(
                          value: risk.score / 100,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation(risk.tier.color),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${risk.score.round()}',
                            style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink),
                          ),
                          const Text('/ 100',
                              style: TextStyle(
                                  color: AppTheme.ink60, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RiskBadge(tier: risk.tier),
                const SizedBox(height: 8),
                Text(
                  _riskDescription(risk.score),
                  style: const TextStyle(
                      color: AppTheme.ink60, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-Day Adherence Trend',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 14),
                AdherenceChart(weeklyRates: stats.weeklyRates),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(l.t('whyThis'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                for (final f in risk.factors) ...[
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (f.weight > 0 ? AppTheme.error : AppTheme.secondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        f.weight > 0
                            ? Icons.trending_up
                            : f.weight < 0
                                ? Icons.trending_down
                                : Icons.remove,
                        color: f.weight > 0
                            ? AppTheme.error
                            : f.weight < 0
                                ? AppTheme.secondary
                                : AppTheme.ink60,
                        size: 18,
                      ),
                    ),
                    title: Text(f.label,
                        style: const TextStyle(fontSize: 13.5)),
                    trailing: f.weight == 0
                        ? null
                        : Text(
                            '${f.weight > 0 ? '+' : ''}${f.weight.round()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: f.weight > 0
                                  ? AppTheme.error
                                  : AppTheme.secondary,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: AppTheme.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This score is computed privately on your device from your '
                    'dose history. It is shared with your clinic only when you '
                    'choose to.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _riskDescription(double score) {
    if (score < 30) return 'Your adherence is excellent. Keep maintaining your current routine.';
    if (score < 60) return 'Some missed doses detected. Consistent adherence helps prevent complications.';
    return 'Your healthcare provider has been notified. Please reach out to your clinic soon.';
  }
}
