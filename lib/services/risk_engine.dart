import 'dart:math' as math;

import '../models/dose_event.dart';
import '../models/enums.dart';
import '../models/risk_assessment.dart';

/// Siyaphila's early-warning non-adherence model.
///
/// This is a transparent, rule-based stand-in for the production ML model. It
/// is deliberately *explainable*: it returns the individual behavioral signals
/// (and their weights) that drive the score, which is exactly what a clinician
/// dashboard needs in order to trust an automated flag.
///
/// A trained model can later replace [assess] behind the same signature without
/// touching any UI — the input (longitudinal [DoseEvent]s) and output
/// ([RiskAssessment]) contract stays identical.
class RiskEngine {
  const RiskEngine();

  RiskAssessment assess(List<DoseEvent> events, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final resolved = events
        .where((e) =>
            e.status != DoseStatus.upcoming && e.status != DoseStatus.due)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

    if (resolved.length < 3) {
      return RiskAssessment(
        score: 0,
        tier: RiskTier.low,
        factors: const [RiskFactor('Not enough history yet', 0)],
        computedAt: clock,
      );
    }

    final factors = <RiskFactor>[];
    var score = 0.0;

    // 1. Baseline miss rate over the whole window.
    final missRate = _missRate(resolved);
    final missContribution = missRate * 35; // up to +35
    if (missContribution > 1) {
      factors.add(RiskFactor(
          'Overall miss rate ${(missRate * 100).round()}%', missContribution));
      score += missContribution;
    }

    // 2. Recent deterioration: last 7 days vs the prior baseline.
    final trend = _recentTrend(resolved, clock);
    if (trend > 0.05) {
      final c = math.min(trend * 60, 25.0); // up to +25
      factors.add(RiskFactor(
          'Adherence slipping in the last week (${(trend * 100).round()}% worse)',
          c));
      score += c;
    } else if (trend < -0.05) {
      final c = math.max(trend * 20, -10.0); // improving lowers risk
      factors.add(const RiskFactor('Recently improving', -8));
      score += c;
    }

    // 3. Dose-time drift: confirmations creeping later within their windows.
    final drift = _doseTimeDrift(resolved);
    if (drift > 15) {
      final c = math.min((drift - 15) / 3, 15.0); // up to +15
      factors.add(
          RiskFactor('Dose times drifting ~${drift.round()} min later', c));
      score += c;
    }

    // 4. Ignored alerts — alerts delivered but the dose was never acted on.
    final ignoredRate = _ignoredRate(resolved);
    if (ignoredRate > 0) {
      final c = math.min(ignoredRate * 20, 15.0); // up to +15
      factors.add(RiskFactor(
          '${(ignoredRate * 100).round()}% of alerts ignored', c));
      score += c;
    }

    // 5. Broken streak momentum: consecutive recent missed days.
    final consecMissedDays = _consecutiveMissedDays(resolved, clock);
    if (consecMissedDays >= 2) {
      final c = math.min(consecMissedDays * 6.0, 18.0); // up to +18
      factors.add(RiskFactor(
          '$consecMissedDays day(s) in a row with a missed dose', c));
      score += c;
    }

    score = score.clamp(0, 100).toDouble();
    if (factors.isEmpty) {
      factors.add(const RiskFactor('Consistent, on-time adherence', 0));
    }

    return RiskAssessment(
      score: score,
      tier: RiskAssessment.tierForScore(score),
      factors: factors..sort((a, b) => b.weight.compareTo(a.weight)),
      computedAt: clock,
    );
  }

  double _missRate(List<DoseEvent> events) {
    final missed = events
        .where((e) =>
            e.status == DoseStatus.missed || e.status == DoseStatus.ignored)
        .length;
    return missed / events.length;
  }

  /// Positive = recent week is worse than the prior baseline.
  double _recentTrend(List<DoseEvent> events, DateTime now) {
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = events.where((e) => e.scheduledFor.isAfter(weekAgo)).toList();
    final prior =
        events.where((e) => !e.scheduledFor.isAfter(weekAgo)).toList();
    if (recent.isEmpty || prior.isEmpty) return 0;
    return _missRate(recent) - _missRate(prior);
  }

  /// Average positive delay (minutes) of confirmed doses — lateness creep.
  double _doseTimeDrift(List<DoseEvent> events) {
    final delays = events
        .where((e) => e.delayMinutes != null && e.delayMinutes! > 0)
        .map((e) => e.delayMinutes!.toDouble())
        .toList();
    if (delays.isEmpty) return 0;
    return delays.reduce((a, b) => a + b) / delays.length;
  }

  double _ignoredRate(List<DoseEvent> events) {
    final alerted = events.where((e) => e.alertDelivered).toList();
    if (alerted.isEmpty) return 0;
    final ignored =
        alerted.where((e) => e.status == DoseStatus.ignored).length;
    return ignored / alerted.length;
  }

  int _consecutiveMissedDays(List<DoseEvent> events, DateTime now) {
    final byDay = <DateTime, List<DoseEvent>>{};
    for (final e in events) {
      final k = DateTime(
          e.scheduledFor.year, e.scheduledFor.month, e.scheduledFor.day);
      byDay.putIfAbsent(k, () => []).add(e);
    }
    var cursor = DateTime(now.year, now.month, now.day);
    if (!byDay.containsKey(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (byDay.containsKey(cursor)) {
      final dayMissed = byDay[cursor]!.any((e) =>
          e.status == DoseStatus.missed || e.status == DoseStatus.ignored);
      if (dayMissed) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }
}
