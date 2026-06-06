import 'package:flutter/foundation.dart';

import '../models/adherence_stats.dart';
import '../models/dose_event.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../models/risk_assessment.dart';
import 'adherence_calculator.dart';
import 'notification_service.dart';
import 'risk_engine.dart';
import 'storage_service.dart';

/// Central application store. Owns the patient, the longitudinal dose log, and
/// the derived adherence + risk state, and persists every change offline.
class AppState extends ChangeNotifier {
  AppState({
    required StorageService storage,
    required NotificationService notifications,
    AdherenceCalculator calculator = const AdherenceCalculator(),
    RiskEngine riskEngine = const RiskEngine(),
  })  : _storage = storage,
        _notifications = notifications,
        _calculator = calculator,
        _riskEngine = riskEngine;

  final StorageService _storage;
  final NotificationService _notifications;
  final AdherenceCalculator _calculator;
  final RiskEngine _riskEngine;

  PatientProfile? _patient;
  List<DoseEvent> _events = [];

  PatientProfile? get patient => _patient;
  bool get isOnboarded => _storage.isOnboarded && _patient != null;
  NotificationService get notifications => _notifications;
  List<DoseEvent> get events => List.unmodifiable(_events);

  AdherenceStats get stats => _calculator.compute(_events);
  RiskAssessment get risk => _riskEngine.assess(_events);

  AppLanguage get language => _patient?.language ?? AppLanguage.english;

  /// Load persisted state and reconcile today's schedule with the clock.
  Future<void> load() async {
    _patient = _storage.loadPatient();
    _events = _storage.loadEvents();
    if (_patient != null) {
      _ensureTodaysDoses();
      _recomputeStatuses();
      await _persist();
      await _scheduleReminders();
    }
    notifyListeners();
  }

  /// Seed a brand-new install (or onboarding result) and persist it.
  Future<void> onboard(PatientProfile patient,
      {List<DoseEvent> history = const []}) async {
    _patient = patient;
    _events = [...history];
    _ensureTodaysDoses();
    _recomputeStatuses();
    await _storage.setOnboarded(true);
    await _persist();
    await _scheduleReminders();
    notifyListeners();
  }

  List<DoseEvent> todaysDoses() {
    final today = _dateOnly(DateTime.now());
    final list = _events
        .where((e) => _dateOnly(e.scheduledFor) == today)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return list;
  }

  List<DoseEvent> eventsForMedication(String medicationId) => _events
      .where((e) => e.medicationId == medicationId)
      .toList()
    ..sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));

  Medication? medicationById(String id) {
    for (final m in _patient?.medications ?? const <Medication>[]) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The Proof-of-Dose action: confirm a dose with a verification method.
  Future<void> confirmDose(DoseEvent event, ProofMethod method) async {
    final med = medicationById(event.medicationId);
    final now = DateTime.now();
    final window = med?.windowMinutes ?? 60;
    final lateBy = now.difference(event.scheduledFor).inMinutes;
    final status = lateBy.abs() <= window ? DoseStatus.taken : DoseStatus.late;
    _replaceEvent(event.copyWith(
      status: status,
      confirmedAt: now,
      proofMethod: method,
    ));
    await _persist();
    notifyListeners();
  }

  Future<void> markModuleRead(String moduleId) async {
    if (_patient == null) return;
    _patient!.readModuleIds.add(moduleId);
    await _persist();
    notifyListeners();
  }

  Future<void> changeLanguage(AppLanguage language) async {
    if (_patient == null) return;
    _patient!.language = language;
    await _persist();
    notifyListeners();
  }

  Future<void> addMedication(Medication medication) async {
    if (_patient == null) return;
    _patient!.medications.add(medication);
    _ensureTodaysDoses();
    _recomputeStatuses();
    await _persist();
    await _scheduleReminders();
    notifyListeners();
  }

  Future<void> reset() async {
    await _notifications.cancelAll();
    await _storage.clear();
    _patient = null;
    _events = [];
    notifyListeners();
  }

  // --- internals -----------------------------------------------------------

  /// Materialize a [DoseEvent] for every scheduled time today that lacks one.
  void _ensureTodaysDoses() {
    if (_patient == null) return;
    final now = DateTime.now();
    final today = _dateOnly(now);
    final existing = _events
        .where((e) => _dateOnly(e.scheduledFor) == today)
        .map((e) => '${e.medicationId}@${e.scheduledFor.toIso8601String()}')
        .toSet();

    for (final med in _patient!.medications) {
      for (final t in med.scheduleTimes) {
        final when =
            DateTime(today.year, today.month, today.day, t.hour, t.minute);
        final key = '${med.id}@${when.toIso8601String()}';
        if (!existing.contains(key)) {
          _events.add(DoseEvent(
            id: 'dose_${med.id}_${when.millisecondsSinceEpoch}',
            medicationId: med.id,
            scheduledFor: when,
            status: DoseStatus.upcoming,
          ));
        }
      }
    }
  }

  /// Advance unresolved dose statuses according to the current time/window.
  void _recomputeStatuses() {
    final now = DateTime.now();
    for (var i = 0; i < _events.length; i++) {
      final e = _events[i];
      if (e.status != DoseStatus.upcoming && e.status != DoseStatus.due) {
        continue;
      }
      final med = medicationById(e.medicationId);
      final window = med?.windowMinutes ?? 60;
      final opensAt = e.scheduledFor.subtract(const Duration(minutes: 15));
      final closesAt = e.scheduledFor.add(Duration(minutes: window));
      if (now.isAfter(closesAt)) {
        _events[i] = e.copyWith(status: DoseStatus.missed, alertDelivered: true);
      } else if (now.isAfter(opensAt)) {
        _events[i] = e.copyWith(status: DoseStatus.due, alertDelivered: true);
      }
    }
  }

  void _replaceEvent(DoseEvent updated) {
    final idx = _events.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      _events[idx] = updated;
    } else {
      _events.add(updated);
    }
  }

  Future<void> _scheduleReminders() async {
    await _notifications.cancelAll();
    for (final med in _patient?.medications ?? const <Medication>[]) {
      await _notifications.scheduleForToday(med);
    }
  }

  Future<void> _persist() async {
    if (_patient != null) await _storage.savePatient(_patient!);
    await _storage.saveEvents(_events);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
