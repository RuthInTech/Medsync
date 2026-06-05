import 'enums.dart';

/// A localized educational/lifestyle module tied to a condition.
///
/// The [titleKey] and [bodyKey] resolve against [AppLocalizations] so the same
/// module renders in the patient's chosen language.
class EducationModule {
  const EducationModule({
    required this.id,
    required this.condition,
    required this.titleKey,
    required this.bodyKey,
    required this.readMinutes,
  });

  final String id;
  final ConditionType condition;
  final String titleKey;
  final String bodyKey;
  final int readMinutes;
}
