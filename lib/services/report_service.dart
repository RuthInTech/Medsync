import '../models/adherence_stats.dart';
import '../models/dose_event.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../models/risk_assessment.dart';

/// Builds a plain-text adherence summary a patient can share with their doctor.
///
/// Text (rather than PDF) keeps the demo dependency-light and trivially
/// shareable via the OS share sheet / clipboard; the structure maps 1:1 to a
/// clinic-ready report.
class ReportService {
  const ReportService();

  String buildSummary({
    required PatientProfile patient,
    required List<DoseEvent> events,
    required AdherenceStats stats,
    required RiskAssessment risk,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final b = StringBuffer();
    b.writeln('MEDISYNC — ADHERENCE SUMMARY');
    b.writeln('Generated: ${_date(clock)}');
    b.writeln('=' * 40);
    b.writeln('Patient: ${patient.name}  (age ${patient.age})');
    b.writeln('Conditions: ${patient.conditions.map((c) => c.label).join(', ')}');
    b.writeln('');
    b.writeln('OVERALL ADHERENCE');
    b.writeln('  Completion: ${stats.completionPercent}%'
        ' (${stats.takenCount}/${stats.totalDue} doses)');
    b.writeln('  Current streak: ${stats.currentStreak} days'
        ' (best ${stats.bestStreak})');
    b.writeln('  Missed doses: ${stats.missedCount}');
    b.writeln('');
    b.writeln('RISK ASSESSMENT');
    b.writeln('  Tier: ${risk.tier.label}  (score ${risk.score.round()}/100)');
    for (final f in risk.factors) {
      final sign = f.weight > 0 ? '▲' : (f.weight < 0 ? '▼' : '•');
      b.writeln('  $sign ${f.label}');
    }
    b.writeln('');
    b.writeln('PER-MEDICATION');
    for (final med in patient.medications) {
      final medEvents =
          events.where((e) => e.medicationId == med.id).toList();
      b.writeln('  ${med.name} (${med.dosageAmount}) — ${med.condition.label}');
      b.writeln('    ${_medLine(med, medEvents)}');
    }
    b.writeln('');
    b.writeln('Shared from the Medisync patient app.');
    return b.toString();
  }

  String _medLine(Medication med, List<DoseEvent> events) {
    final resolved = events
        .where((e) =>
            e.status != DoseStatus.upcoming && e.status != DoseStatus.due)
        .toList();
    if (resolved.isEmpty) return 'No completed doses yet.';
    final taken = resolved.where((e) => e.status.isAdherent).length;
    final pct = ((taken / resolved.length) * 100).round();
    return '$pct% adherent ($taken/${resolved.length}), '
        '${med.scheduleTimes.length}×/day';
  }

  String _date(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)} ${_pad(d.hour)}:${_pad(d.minute)}';
  String _pad(int n) => n.toString().padLeft(2, '0');
}
