import '../models/dose_event.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../models/patient.dart';

/// Deterministic demo data: a realistic multi-condition patient with a 30-day
/// longitudinal history, plus a roster of synthetic patients (varied risk) for
/// the clinician dashboard.
///
/// Determinism (a seeded pseudo-random generator) keeps the demo stable across
/// launches and makes the risk engine's output reproducible.
class SeedData {
  const SeedData._();

  static PatientProfile demoPatient() => PatientProfile(
        id: 'patient_demo',
        name: 'Thandiwe Nkosi',
        age: 47,
        language: AppLanguage.english,
        conditions: const [
          ConditionType.diabetes,
          ConditionType.hypertension,
          ConditionType.hiv,
        ],
        medications: [
          Medication(
            id: 'med_metformin',
            name: 'Metformin',
            condition: ConditionType.diabetes,
            dosageAmount: '500 mg',
            scheduleTimes: const [DoseTime(8, 0), DoseTime(20, 0)],
            instructions: 'Take with food.',
            windowMinutes: 60,
            proofMethod: ProofMethod.tap,
          ),
          Medication(
            id: 'med_amlodipine',
            name: 'Amlodipine',
            condition: ConditionType.hypertension,
            dosageAmount: '5 mg',
            scheduleTimes: const [DoseTime(8, 0)],
            instructions: 'Take in the morning.',
            windowMinutes: 90,
            proofMethod: ProofMethod.tap,
          ),
          Medication(
            id: 'med_tld',
            name: 'TLD (ART)',
            condition: ConditionType.hiv,
            dosageAmount: '1 tablet',
            scheduleTimes: const [DoseTime(21, 0)],
            instructions: 'Same time every night.',
            windowMinutes: 60,
            proofMethod: ProofMethod.photo,
          ),
        ],
      );

  /// 30 days of history for the demo patient, gently deteriorating over the
  /// last week so the engine surfaces a "slipping" early warning.
  static List<DoseEvent> demoHistory(PatientProfile patient) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rng = _Lcg(42);
    final events = <DoseEvent>[];

    for (var dayOffset = 30; dayOffset >= 1; dayOffset--) {
      final day = today.subtract(Duration(days: dayOffset));
      // Adherence probability worsens over the most recent 7 days.
      final pTake = dayOffset <= 7 ? 0.62 : 0.94;
      for (final med in patient.medications) {
        for (final t in med.scheduleTimes) {
          final scheduled =
              DateTime(day.year, day.month, day.day, t.hour, t.minute);
          final roll = rng.nextDouble();
          if (roll < pTake) {
            // Taken — late more often in the recent slipping window.
            final lateChance = dayOffset <= 7 ? 0.5 : 0.15;
            final isLate = rng.nextDouble() < lateChance;
            final delay = isLate
                ? med.windowMinutes + 10 + rng.nextInt(40)
                : rng.nextInt(med.windowMinutes ~/ 2);
            events.add(DoseEvent(
              id: 'h_${med.id}_${scheduled.millisecondsSinceEpoch}',
              medicationId: med.id,
              scheduledFor: scheduled,
              status: isLate ? DoseStatus.late : DoseStatus.taken,
              confirmedAt: scheduled.add(Duration(minutes: delay)),
              proofMethod: med.proofMethod,
              alertDelivered: true,
            ));
          } else {
            // Missed or ignored.
            final ignored = rng.nextDouble() < 0.5;
            events.add(DoseEvent(
              id: 'h_${med.id}_${scheduled.millisecondsSinceEpoch}',
              medicationId: med.id,
              scheduledFor: scheduled,
              status: ignored ? DoseStatus.ignored : DoseStatus.missed,
              alertDelivered: true,
            ));
          }
        }
      }
    }
    return events;
  }

  /// Synthetic roster for the clinician dashboard. Each entry carries its own
  /// pre-computed history so the dashboard can run the real risk engine on it.
  static List<RosterPatient> clinicRoster() {
    return [
      _roster('p1', 'Sipho Dlamini', 52,
          [ConditionType.tuberculosis, ConditionType.hiv], 0.55, true),
      _roster('p2', 'Aisha Patel', 39, [ConditionType.diabetes], 0.97, false),
      _roster('p3', 'Johan van Wyk', 61,
          [ConditionType.hypertension, ConditionType.highCholesterol], 0.78,
          false),
      _roster('p4', 'Nomsa Khumalo', 44,
          [ConditionType.hiv, ConditionType.diabetes], 0.48, true),
      _roster('p5', 'Lerato Mokoena', 29, [ConditionType.tuberculosis], 0.99,
          false),
      _roster('p6', 'David Smith', 57,
          [ConditionType.hypertension, ConditionType.diabetes], 0.7, false),
    ];
  }

  static RosterPatient _roster(String id, String name, int age,
      List<ConditionType> conditions, double pTake, bool deteriorating) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rng = _Lcg(id.hashCode & 0x7fffffff);
    final events = <DoseEvent>[];
    for (var dayOffset = 21; dayOffset >= 1; dayOffset--) {
      final day = today.subtract(Duration(days: dayOffset));
      final effP = deteriorating && dayOffset <= 7 ? pTake - 0.25 : pTake;
      for (final c in conditions) {
        final scheduled = DateTime(day.year, day.month, day.day, 8, 0);
        final medId = 'r_${id}_${c.name}';
        if (rng.nextDouble() < effP) {
          final isLate = rng.nextDouble() < (deteriorating ? 0.4 : 0.12);
          events.add(DoseEvent(
            id: 'e_${medId}_$dayOffset',
            medicationId: medId,
            scheduledFor: scheduled,
            status: isLate ? DoseStatus.late : DoseStatus.taken,
            confirmedAt: scheduled.add(Duration(minutes: isLate ? 95 : 10)),
            proofMethod: ProofMethod.tap,
            alertDelivered: true,
          ));
        } else {
          events.add(DoseEvent(
            id: 'e_${medId}_$dayOffset',
            medicationId: medId,
            scheduledFor: scheduled,
            status:
                rng.nextDouble() < 0.5 ? DoseStatus.ignored : DoseStatus.missed,
            alertDelivered: true,
          ));
        }
      }
    }
    return RosterPatient(
        id: id, name: name, age: age, conditions: conditions, events: events);
  }
}

/// A non-interactive patient shown on the clinician dashboard.
class RosterPatient {
  const RosterPatient({
    required this.id,
    required this.name,
    required this.age,
    required this.conditions,
    required this.events,
  });

  final String id;
  final String name;
  final int age;
  final List<ConditionType> conditions;
  final List<DoseEvent> events;
}

/// Tiny deterministic linear-congruential generator (no dart:math.Random seed
/// reliance needed; fully reproducible across runs).
class _Lcg {
  _Lcg(int seed) : _state = seed & 0x7fffffff;
  int _state;

  int _next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;
  int nextInt(int max) => max <= 0 ? 0 : _next() % max;
}
