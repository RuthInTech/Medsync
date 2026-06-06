import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/risk_badge.dart';
import '../models/enums.dart';

class ClinicianTab extends StatefulWidget {
  const ClinicianTab({super.key});

  @override
  State<ClinicianTab> createState() => _ClinicianTabState();
}

class _ClinicianTabState extends State<ClinicianTab> {
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;
  String? _error;
  String _clinicianName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      final token = await auth.getToken();
      _clinicianName = await auth.getName() ?? 'Clinician';
      final api = ApiService(token: token);
      final list = await api.getList('/clinician/roster');
      if (mounted) {
        setState(() {
          _patients = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Connection failed. Pull down to retry.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagged = _patients.where((p) => p['risk_tier'] == 'high').toList();

    return Column(
      children: [
        _ClinicianHeader(
          clinicianName: _clinicianName,
          flaggedCount: flagged.length,
          onRefresh: _load,
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : _patients.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                            children: [
                              if (flagged.isNotEmpty) ...[
                                _SectionHeader(
                                  label: 'Flagged patients',
                                  count: flagged.length,
                                  countColor: AppTheme.error,
                                ),
                                const SizedBox(height: 10),
                                for (final p in flagged)
                                  _PatientCard(patient: p, highlighted: true),
                                const SizedBox(height: 20),
                              ],
                              _SectionHeader(
                                  label: 'All patients', count: _patients.length),
                              const SizedBox(height: 10),
                              for (final p in _patients)
                                _PatientCard(patient: p, highlighted: false),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ClinicianHeader extends StatelessWidget {
  const _ClinicianHeader({
    required this.clinicianName,
    required this.flaggedCount,
    required this.onRefresh,
  });
  final String clinicianName;
  final int flaggedCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clinic Dashboard',
                        style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      flaggedCount > 0
                          ? '$flaggedCount patient${flaggedCount == 1 ? '' : 's'} need attention'
                          : 'All patients in good standing',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      clinicianName.split(' ').first,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Patient card ──────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.highlighted});
  final Map<String, dynamic> patient;
  final bool highlighted;

  RiskTier get _tier {
    return switch (patient['risk_tier'] as String? ?? 'low') {
      'high' => RiskTier.high,
      'medium' => RiskTier.medium,
      _ => RiskTier.low,
    };
  }

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Unknown';
    final age = patient['age'] as int? ?? 0;
    final score = (patient['risk_score'] as num?)?.toDouble() ?? 0.0;
    final adherence = (patient['adherence_rate'] as num?)?.toDouble() ?? 1.0;
    final rawConditions = (patient['conditions'] as List<dynamic>?) ?? [];
    final tier = _tier;

    final borderColor = highlighted
        ? AppTheme.error.withValues(alpha: 0.3)
        : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: tier.color.withValues(alpha: 0.12),
          child: Text(
            name.characters.first.toUpperCase(),
            style: TextStyle(color: tier.color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          _subtitleText(age, rawConditions),
          style: const TextStyle(fontSize: 12, color: AppTheme.ink60),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: RiskBadge(tier: tier, score: score),
        children: [
          const Divider(height: 16),
          _statRow(Icons.check_circle_outline, 'Adherence',
              '${(adherence * 100).toStringAsFixed(0)}%',
              adherence >= 0.8 ? AppTheme.secondary : AppTheme.error),
          _statRow(Icons.insights_outlined, 'Risk score',
              '${score.toStringAsFixed(1)} / 100', tier.color),
          if (highlighted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Outreach logged for $name'),
                    backgroundColor: AppTheme.secondary,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  minimumSize: const Size.fromHeight(40),
                ),
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Schedule outreach', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _subtitleText(int age, List<dynamic> conditions) {
    final parts = <String>['${age}y'];
    if (conditions.isNotEmpty) {
      parts.add(conditions.map(_conditionLabel).join(' · '));
    }
    return parts.join(' · ');
  }

  String _conditionLabel(dynamic raw) {
    final s = raw.toString();
    return switch (s) {
      'diabetes' => 'Diabetes',
      'hypertension' => 'Hypertension',
      'hiv' => 'HIV',
      'highCholesterol' => 'High Cholesterol',
      'tuberculosis' => 'Tuberculosis',
      _ => s,
    };
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.ink60)),
          const Spacer(),
          Text(value,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count, this.countColor});
  final String label;
  final int count;
  final Color? countColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (countColor ?? AppTheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: countColor ?? AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      ],
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: AppTheme.ink60),
          SizedBox(height: 12),
          Text('No onboarded patients yet',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink60)),
          SizedBox(height: 6),
          Text('Patients will appear here once they complete setup.',
              style: TextStyle(fontSize: 13, color: AppTheme.ink60)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.ink60, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
