import 'enums.dart';
import 'medication.dart';

/// A patient profile: identity, language preference, the chronic conditions
/// they manage, and their full medication regimen.
class PatientProfile {
  PatientProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.language,
    required this.conditions,
    required this.medications,
    Set<String>? readModuleIds,
  }) : readModuleIds = readModuleIds ?? <String>{};

  final String id;
  String name;
  int age;
  AppLanguage language;
  List<ConditionType> conditions;
  List<Medication> medications;

  /// Education modules the patient has opened (feeds the engine + gamification).
  Set<String> readModuleIds;

  List<Medication> medicationsFor(ConditionType c) =>
      medications.where((m) => m.condition == c).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'language': language.code,
        'conditions': conditions.map((c) => c.name).toList(),
        'medications': medications.map((m) => m.toJson()).toList(),
        'readModuleIds': readModuleIds.toList(),
      };

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        language: AppLanguage.fromCode(json['language'] as String),
        conditions: (json['conditions'] as List)
            .map((c) => ConditionType.values.byName(c as String))
            .toList(),
        medications: (json['medications'] as List)
            .map((m) => Medication.fromJson(m as Map<String, dynamic>))
            .toList(),
        readModuleIds:
            ((json['readModuleIds'] as List?) ?? []).map((e) => e as String).toSet(),
      );
}
