import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/adherence_stats.dart';
import '../models/enums.dart';

/// Hero gamification banner: a completion ring plus streak, points and best
/// streak metrics, rendered on the Medisync brand gradient.
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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF18A999), Color(0xFF0E6E7C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E6E7C).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
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
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFFFD166), size: 30),
                    const SizedBox(width: 6),
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
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        l.t('streak'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _metric('${stats.points}', l.t('points')),
                    const SizedBox(width: 24),
                    _metric('${stats.bestStreak}', 'best'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: (percent.clamp(0, 100)) / 100,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFFFD166)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percent%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Text('today',
                  style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
