import 'package:flutter_test/flutter_test.dart';

import 'package:medisync/models/dose_event.dart';
import 'package:medisync/models/enums.dart';
import 'package:medisync/services/adherence_calculator.dart';
import 'package:medisync/services/risk_engine.dart';

void main() {
  DateTime at(int daysAgo, int hour) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, hour);
    return base.subtract(Duration(days: daysAgo));
  }

  DoseEvent taken(int daysAgo, {int delay = 5}) => DoseEvent(
        id: 'e$daysAgo',
        medicationId: 'm',
        scheduledFor: at(daysAgo, 8),
        status: delay > 60 ? DoseStatus.late : DoseStatus.taken,
        confirmedAt: at(daysAgo, 8).add(Duration(minutes: delay)),
        alertDelivered: true,
      );

  DoseEvent missed(int daysAgo) => DoseEvent(
        id: 'm$daysAgo',
        medicationId: 'm',
        scheduledFor: at(daysAgo, 8),
        status: DoseStatus.missed,
        alertDelivered: true,
      );

  group('AdherenceCalculator', () {
    test('perfect history yields a full streak and 100% completion', () {
      final events = [for (var d = 1; d <= 5; d++) taken(d)];
      final stats = const AdherenceCalculator().compute(events);
      expect(stats.completionPercent, 100);
      expect(stats.currentStreak, 5);
      expect(stats.points, greaterThan(0));
    });

    test('a missed dose breaks the current streak', () {
      final events = [taken(3), missed(2), taken(1)];
      final stats = const AdherenceCalculator().compute(events);
      expect(stats.currentStreak, 1); // only yesterday counts
      expect(stats.missedCount, 1);
    });
  });

  group('RiskEngine', () {
    test('consistent adherence is low risk', () {
      final events = [for (var d = 1; d <= 14; d++) taken(d)];
      final risk = const RiskEngine().assess(events);
      expect(risk.tier, RiskTier.low);
      expect(risk.score, lessThan(30));
    });

    test('frequent recent misses raise the risk score', () {
      final events = <DoseEvent>[
        for (var d = 8; d <= 21; d++) taken(d),
        for (var d = 1; d <= 7; d++) missed(d),
      ];
      final risk = const RiskEngine().assess(events);
      expect(risk.score, greaterThan(30));
      expect(risk.factors.length, greaterThan(1));
    });

    test('round-trips a DoseEvent through JSON', () {
      final e = taken(1);
      final back = DoseEvent.fromJson(e.toJson());
      expect(back.status, e.status);
      expect(back.scheduledFor, e.scheduledFor);
      expect(back.delayMinutes, e.delayMinutes);
    });
  });
}
