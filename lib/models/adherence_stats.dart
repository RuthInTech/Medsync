/// Aggregated gamification + adherence metrics derived from dose history.
///
/// Pure value object — computed by [AdherenceCalculator], never persisted.
class AdherenceStats {
  const AdherenceStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.points,
    required this.takenCount,
    required this.missedCount,
    required this.totalDue,
    required this.weeklyRates,
  });

  /// Consecutive fully-adherent days ending today.
  final int currentStreak;
  final int bestStreak;

  /// 0.0–1.0 across the evaluated history.
  final double completionRate;

  /// Behavioral reward points.
  final int points;

  final int takenCount;
  final int missedCount;
  final int totalDue;

  /// Last 7 days of completion rate (oldest → newest), 0.0–1.0.
  final List<double> weeklyRates;

  int get completionPercent => (completionRate * 100).round();

  factory AdherenceStats.empty() => const AdherenceStats(
        currentStreak: 0,
        bestStreak: 0,
        completionRate: 0,
        points: 0,
        takenCount: 0,
        missedCount: 0,
        totalDue: 0,
        weeklyRates: [],
      );
}
