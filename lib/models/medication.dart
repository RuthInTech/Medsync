import 'enums.dart';

/// A simple time-of-day value (24h) that survives JSON round-trips cleanly.
class DoseTime {
  const DoseTime(this.hour, this.minute);

  final int hour;
  final int minute;

  /// Minutes since midnight — handy for window comparisons.
  int get minutesOfDay => hour * 60 + minute;

  String format() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory DoseTime.fromJson(Map<String, dynamic> json) =>
      DoseTime(json['hour'] as int, json['minute'] as int);
}

/// A prescribed medication belonging to one chronic condition.
///
/// Carries the physician-defined schedule and the grace window (in minutes)
/// used to decide whether a confirmation counts as on-time or late.
class Medication {
  Medication({
    required this.id,
    required this.name,
    required this.condition,
    required this.dosageAmount,
    required this.scheduleTimes,
    this.instructions = '',
    this.windowMinutes = 60,
    this.proofMethod = ProofMethod.tap,
  });

  final String id;
  final String name;
  final ConditionType condition;

  /// Free-text dosage, e.g. "500 mg", "10 units".
  final String dosageAmount;

  /// Physician-prescribed times of day this medication is taken.
  final List<DoseTime> scheduleTimes;

  final String instructions;

  /// Grace period around each scheduled time before a dose is "late".
  final int windowMinutes;

  /// Default verification method required to mark a dose as taken.
  final ProofMethod proofMethod;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'condition': condition.name,
        'dosageAmount': dosageAmount,
        'scheduleTimes': scheduleTimes.map((t) => t.toJson()).toList(),
        'instructions': instructions,
        'windowMinutes': windowMinutes,
        'proofMethod': proofMethod.name,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        name: json['name'] as String,
        condition: ConditionType.values.byName(json['condition'] as String),
        dosageAmount: json['dosageAmount'] as String,
        scheduleTimes: (json['scheduleTimes'] as List)
            .map((t) => DoseTime.fromJson(t as Map<String, dynamic>))
            .toList(),
        instructions: json['instructions'] as String? ?? '',
        windowMinutes: json['windowMinutes'] as int? ?? 60,
        proofMethod:
            ProofMethod.values.byName(json['proofMethod'] as String? ?? 'tap'),
      );
}
