import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/adherence_stats.dart';
import '../models/enums.dart';
import '../theme.dart';

class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.stats,
    required this.language,
  });

  final AdherenceStats stats;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(language);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.greenGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CompletionRing(percent: stats.completionPercent),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${stats.currentStreak}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        l.t('streak'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Metric('${stats.points}', l.t('points')),
                    const SizedBox(width: 20),
                    _Metric('${stats.bestStreak}', 'best'),
                    const SizedBox(width: 20),
                    _Metric('${stats.takenCount}', 'taken'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: CircularProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Text('today',
                  style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
