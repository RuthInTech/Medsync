import 'enums.dart';

/// A single explainable factor that pushed a patient's risk score up or down.
class RiskFactor {
  const RiskFactor(this.label, this.weight);

  /// Human-readable description, e.g. "Dose times drifting later".
  final String label;

  /// Contribution to the 0–100 risk score (positive = riskier).
  final double weight;

  Map<String, dynamic> toJson() => {'label': label, 'weight': weight};

  factory RiskFactor.fromJson(Map<String, dynamic> json) =>
      RiskFactor(json['label'] as String, (json['weight'] as num).toDouble());
}

/// Output of the predictive engine for one patient at a point in time.
class RiskAssessment {
  const RiskAssessment({
    required this.score,
    required this.tier,
    required this.factors,
    required this.computedAt,
  });

  /// 0 (fully adherent) – 100 (imminent default).
  final double score;
  final RiskTier tier;
  final List<RiskFactor> factors;
  final DateTime computedAt;

  static RiskTier tierForScore(double score) {
    if (score >= 60) return RiskTier.high;
    if (score >= 30) return RiskTier.medium;
    return RiskTier.low;
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'tier': tier.name,
        'factors': factors.map((f) => f.toJson()).toList(),
        'computedAt': computedAt.toIso8601String(),
      };

  factory RiskAssessment.fromJson(Map<String, dynamic> json) => RiskAssessment(
        score: (json['score'] as num).toDouble(),
        tier: RiskTier.values.byName(json['tier'] as String),
        factors: (json['factors'] as List)
            .map((f) => RiskFactor.fromJson(f as Map<String, dynamic>))
            .toList(),
        computedAt: DateTime.parse(json['computedAt'] as String),
      );
}
