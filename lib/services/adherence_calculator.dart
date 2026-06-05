import '../models/adherence_stats.dart';
import '../models/dose_event.dart';
import '../models/enums.dart';

/// Derives gamification + adherence metrics from a patient's dose history.
///
/// Stateless and pure: same input always yields the same stats, which keeps the
/// streak/percentage/points displays deterministic and testable.
class AdherenceCalculator {
  const AdherenceCalculator();

  /// Points awarded per adherence outcome.
  static const int _pointsOnTime = 10;
  static const int _pointsLate = 5;
  static const int _streakBonus = 25; // per full-adherence day

  AdherenceStats compute(List<DoseEvent> events, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    if (events.isEmpty) return AdherenceStats.empty();

    // Only doses whose window has already resolved count toward rates.
    final resolved = events
        .where((e) => e.status != DoseStatus.upcoming && e.status != DoseStatus.due)
        .toList();

    final taken = resolved.where((e) => e.status.isAdherent).length;
    final missed = resolved
        .where((e) =>
            e.status == DoseStatus.missed || e.status == DoseStatus.ignored)
        .length;
    final total = resolved.length;
    final rate = total == 0 ? 0.0 : taken / total;

    final byDay = _groupByDay(resolved);
    final currentStreak = _currentStreak(byDay, today);
    final bestStreak = _bestStreak(byDay);

    var points = 0;
    for (final e in resolved) {
      if (e.status == DoseStatus.taken) points += _pointsOnTime;
      if (e.status == DoseStatus.late) points += _pointsLate;
    }
    points += _fullAdherenceDays(byDay) * _streakBonus;

    return AdherenceStats(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completionRate: rate,
      points: points,
      takenCount: taken,
      missedCount: missed,
      totalDue: total,
      weeklyRates: _weeklyRates(byDay, today),
    );
  }

  Map<DateTime, List<DoseEvent>> _groupByDay(List<DoseEvent> events) {
    final map = <DateTime, List<DoseEvent>>{};
    for (final e in events) {
      final key = _dateOnly(e.scheduledFor);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  bool _dayIsFullyAdherent(List<DoseEvent> day) =>
      day.isNotEmpty && day.every((e) => e.status.isAdherent);

  int _fullAdherenceDays(Map<DateTime, List<DoseEvent>> byDay) =>
      byDay.values.where(_dayIsFullyAdherent).length;

  int _currentStreak(Map<DateTime, List<DoseEvent>> byDay, DateTime today) {
    var streak = 0;
    // Start from the most recent day that actually had scheduled doses.
    var cursor = today;
    // Allow today to be "in progress" — if today has no resolved doses yet,
    // begin counting from yesterday.
    if (!byDay.containsKey(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (byDay.containsKey(cursor)) {
      if (_dayIsFullyAdherent(byDay[cursor]!)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _bestStreak(Map<DateTime, List<DoseEvent>> byDay) {
    final days = byDay.keys.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in days) {
      final adherent = _dayIsFullyAdherent(byDay[d]!);
      final consecutive =
          prev != null && d.difference(prev).inDays == 1;
      if (adherent) {
        run = consecutive ? run + 1 : 1;
      } else {
        run = 0;
      }
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  List<double> _weeklyRates(
      Map<DateTime, List<DoseEvent>> byDay, DateTime today) {
    final rates = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final doses = byDay[day];
      if (doses == null || doses.isEmpty) {
        rates.add(0);
      } else {
        final taken = doses.where((e) => e.status.isAdherent).length;
        rates.add(taken / doses.length);
      }
    }
    return rates;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
