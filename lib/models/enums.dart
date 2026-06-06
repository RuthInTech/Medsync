/// Core enumerations shared across the Medisync domain model.
library;

import 'package:flutter/material.dart';

/// Chronic conditions the platform manages in a single interface.
enum ConditionType {
  diabetes,
  hypertension,
  hiv,
  highCholesterol,
  tuberculosis;

  String get label {
    switch (this) {
      case ConditionType.diabetes:
        return 'Diabetes';
      case ConditionType.hypertension:
        return 'Hypertension';
      case ConditionType.hiv:
        return 'HIV';
      case ConditionType.highCholesterol:
        return 'High Cholesterol';
      case ConditionType.tuberculosis:
        return 'Tuberculosis';
    }
  }

  IconData get icon {
    switch (this) {
      case ConditionType.diabetes:
        return Icons.water_drop_outlined;
      case ConditionType.hypertension:
        return Icons.favorite_outline;
      case ConditionType.hiv:
        return Icons.shield_outlined;
      case ConditionType.highCholesterol:
        return Icons.bloodtype_outlined;
      case ConditionType.tuberculosis:
        return Icons.air_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ConditionType.diabetes:
        return const Color(0xFF2E7DAF);
      case ConditionType.hypertension:
        return const Color(0xFFD7263D);
      case ConditionType.hiv:
        return const Color(0xFF6A4C93);
      case ConditionType.highCholesterol:
        return const Color(0xFFE09F3E);
      case ConditionType.tuberculosis:
        return const Color(0xFF2A9D8F);
    }
  }
}

/// Lifecycle of a single scheduled dose.
enum DoseStatus {
  /// Scheduled but the time window has not yet opened.
  upcoming,

  /// Window is open; awaiting patient action.
  due,

  /// Confirmed taken via a Proof-of-Dose action.
  taken,

  /// Taken, but outside the prescribed window.
  late,

  /// Window closed without confirmation.
  missed,

  /// Alert was delivered but never acknowledged.
  ignored;

  String get label {
    switch (this) {
      case DoseStatus.upcoming:
        return 'Upcoming';
      case DoseStatus.due:
        return 'Due now';
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.late:
        return 'Taken late';
      case DoseStatus.missed:
        return 'Missed';
      case DoseStatus.ignored:
        return 'Ignored';
    }
  }

  /// Whether this status counts as adherent for compliance maths.
  bool get isAdherent => this == DoseStatus.taken || this == DoseStatus.late;
}

/// The verification method used to satisfy Proof-of-Dose.
enum ProofMethod {
  tap,
  photo,
  qrScan;

  String get label {
    switch (this) {
      case ProofMethod.tap:
        return 'Tap confirmation';
      case ProofMethod.photo:
        return 'Photo capture';
      case ProofMethod.qrScan:
        return 'QR / barcode scan';
    }
  }

  IconData get icon {
    switch (this) {
      case ProofMethod.tap:
        return Icons.touch_app_outlined;
      case ProofMethod.photo:
        return Icons.photo_camera_outlined;
      case ProofMethod.qrScan:
        return Icons.qr_code_scanner_outlined;
    }
  }
}

/// Risk stratification tiers produced by the predictive engine.
enum RiskTier {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case RiskTier.low:
        return 'Low risk';
      case RiskTier.medium:
        return 'Medium risk';
      case RiskTier.high:
        return 'High risk';
    }
  }

  Color get color {
    switch (this) {
      case RiskTier.low:
        return const Color(0xFF2A9D8F);
      case RiskTier.medium:
        return const Color(0xFFE09F3E);
      case RiskTier.high:
        return const Color(0xFFD7263D);
    }
  }
}

/// Supported in-app languages (drives content localization).
enum AppLanguage {
  english('en', 'English'),
  amharic('am', 'አማርኛ');

  const AppLanguage(this.code, this.label);
  final String code;
  final String label;

  static AppLanguage fromCode(String code) =>
      AppLanguage.values.firstWhere((l) => l.code == code,
          orElse: () => AppLanguage.english);
}
