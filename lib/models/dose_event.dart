import 'enums.dart';

/// A single longitudinal data point: one scheduled dose and what happened to it.
///
/// This is the atomic record the predictive engine consumes. Every confirmed,
/// missed, late, or ignored dose becomes an immutable timestamped row.
class DoseEvent {
  DoseEvent({
    required this.id,
    required this.medicationId,
    required this.scheduledFor,
    required this.status,
    this.confirmedAt,
    this.proofMethod,
    this.alertDelivered = false,
  });

  final String id;
  final String medicationId;

  /// The exact datetime the dose was prescribed for.
  final DateTime scheduledFor;

  DoseStatus status;

  /// When the patient actually completed the Proof-of-Dose action.
  DateTime? confirmedAt;

  /// How the dose was verified (null until confirmed).
  ProofMethod? proofMethod;

  /// Whether a behavioral alert/notification was delivered for this dose.
  bool alertDelivered;

  /// Signed delay in minutes between schedule and confirmation
  /// (negative = early, positive = late). Null if never confirmed.
  int? get delayMinutes => confirmedAt?.difference(scheduledFor).inMinutes;

  DoseEvent copyWith({
    DoseStatus? status,
    DateTime? confirmedAt,
    ProofMethod? proofMethod,
    bool? alertDelivered,
  }) =>
      DoseEvent(
        id: id,
        medicationId: medicationId,
        scheduledFor: scheduledFor,
        status: status ?? this.status,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        proofMethod: proofMethod ?? this.proofMethod,
        alertDelivered: alertDelivered ?? this.alertDelivered,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'scheduledFor': scheduledFor.toIso8601String(),
        'status': status.name,
        'confirmedAt': confirmedAt?.toIso8601String(),
        'proofMethod': proofMethod?.name,
        'alertDelivered': alertDelivered,
      };

  factory DoseEvent.fromJson(Map<String, dynamic> json) => DoseEvent(
        id: json['id'] as String,
        medicationId: json['medicationId'] as String,
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        status: DoseStatus.values.byName(json['status'] as String),
        confirmedAt: json['confirmedAt'] == null
            ? null
            : DateTime.parse(json['confirmedAt'] as String),
        proofMethod: json['proofMethod'] == null
            ? null
            : ProofMethod.values.byName(json['proofMethod'] as String),
        alertDelivered: json['alertDelivered'] as bool? ?? false,
      );
}
