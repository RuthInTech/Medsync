import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../widgets/adherence_chart.dart';
import '../widgets/risk_badge.dart';

/// Explainable risk breakdown: the score, the contributing behavioral factors,
/// and the recent adherence trend that the engine analysed.
class RiskDetailScreen extends StatelessWidget {
  const RiskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final risk = app.risk;
    final stats = app.stats;
    final l = AppLocalizations(app.patient!.language);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('riskTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: CircularProgressIndicator(
                          value: risk.score / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation(risk.tier.color),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${risk.score.round()}',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.w800)),
                          const Text('/ 100',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RiskBadge(tier: risk.tier),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Last 7 days',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
              child: AdherenceChart(weeklyRates: stats.weeklyRates),
            ),
          ),
          const SizedBox(height: 20),
          Text(l.t('whyThis'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final f in risk.factors)
                    ListTile(
                      leading: Icon(
                        f.weight > 0
                            ? Icons.trending_up
                            : (f.weight < 0
                                ? Icons.trending_down
                                : Icons.remove),
                        color: f.weight > 0
                            ? const Color(0xFFD7263D)
                            : (f.weight < 0
                                ? const Color(0xFF2A9D8F)
                                : Colors.grey),
                      ),
                      title: Text(f.label),
                      trailing: f.weight == 0
                          ? null
                          : Text(
                              '${f.weight > 0 ? '+' : ''}${f.weight.round()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: f.weight > 0
                                    ? const Color(0xFFD7263D)
                                    : const Color(0xFF2A9D8F),
                              ),
                            ),
                    ),
                ],
              ),
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
                Icon(Icons.lock_outline, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This score is computed privately on your device from your '
                    'own dose history. It is shared with your clinic only when '
                    'you choose to.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
