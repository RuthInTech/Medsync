import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dose_event.dart';
import '../models/patient.dart';

/// Offline-first local persistence.
///
/// Everything lives on-device as JSON in [SharedPreferences]; the app is fully
/// functional with no network. A future sync layer would push these same
/// records to a backend when connectivity returns.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kPatient = 'siyaphila.patient';
  static const _kEvents = 'siyaphila.events';
  static const _kOnboarded = 'siyaphila.onboarded';

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isOnboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  PatientProfile? loadPatient() {
    final raw = _prefs.getString(_kPatient);
    if (raw == null) return null;
    return PatientProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePatient(PatientProfile patient) =>
      _prefs.setString(_kPatient, jsonEncode(patient.toJson()));

  List<DoseEvent> loadEvents() {
    final raw = _prefs.getString(_kEvents);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => DoseEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEvents(List<DoseEvent> events) => _prefs.setString(
        _kEvents,
        jsonEncode(events.map((e) => e.toJson()).toList()),
      );

  Future<void> clear() async {
    await _prefs.remove(_kPatient);
    await _prefs.remove(_kEvents);
    await _prefs.remove(_kOnboarded);
  }
}
