import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '40');
  AppLanguage _language = AppLanguage.english;
  final Set<ConditionType> _conditions = {ConditionType.diabetes};
  bool _loading = false;
  int _step = 0; // 0 = language, 1 = profile, 2 = conditions

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Medication _defaultMed(ConditionType c) {
    final id = 'med_${c.name}';
    switch (c) {
      case ConditionType.diabetes:
        return Medication(
            id: id,
            name: 'Metformin',
            condition: c,
            dosageAmount: '500 mg',
            scheduleTimes: const [DoseTime(8, 0), DoseTime(20, 0)]);
      case ConditionType.hypertension:
        return Medication(
            id: id,
            name: 'Amlodipine',
            condition: c,
            dosageAmount: '5 mg',
            scheduleTimes: const [DoseTime(8, 0)]);
      case ConditionType.hiv:
        return Medication(
            id: id,
            name: 'ART (TLD)',
            condition: c,
            dosageAmount: '1 tablet',
            scheduleTimes: const [DoseTime(21, 0)],
            proofMethod: ProofMethod.photo);
      case ConditionType.highCholesterol:
        return Medication(
            id: id,
            name: 'Atorvastatin',
            condition: c,
            dosageAmount: '20 mg',
            scheduleTimes: const [DoseTime(20, 0)]);
      case ConditionType.tuberculosis:
        return Medication(
            id: id,
            name: 'TB regimen',
            condition: c,
            dosageAmount: '1 dose',
            scheduleTimes: const [DoseTime(8, 0)],
            proofMethod: ProofMethod.qrScan);
    }
  }

  Future<void> _createProfile(AppState app) async {
    if (_conditions.isEmpty) return;
    setState(() => _loading = true);
    try {
      final conditions = _conditions.toList();
      final patient = PatientProfile(
        id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim().isEmpty
            ? 'Patient'
            : _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 40,
        language: _language,
        conditions: conditions,
        medications: conditions.map(_defaultMed).toList(),
      );
      await app.onboard(patient);
      await AuthService().setOnboarded();
      widget.onComplete?.call();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useDemo(AppState app) async {
    setState(() => _loading = true);
    try {
      final demo = SeedData.demoPatient()..language = _language;
      await app.onboard(demo, history: SeedData.demoHistory(demo));
      await AuthService().setOnboarded();
      widget.onComplete?.call();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStep(app),
                ),
              ),
            ),
            _buildBottomActions(app),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Siyaphila',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i <= _step ? AppTheme.primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_step + 1} of 3',
            style: TextStyle(color: AppTheme.ink60, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(AppState app) {
    switch (_step) {
      case 0:
        return _buildLanguageStep();
      case 1:
        return _buildProfileStep();
      default:
        return _buildConditionsStep(app);
    }
  }

  Widget _buildLanguageStep() {
    return Column(
      key: const ValueKey('lang'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Choose your language', style: _titleStyle()),
        const SizedBox(height: 8),
        Text('We\'ll show medication info and reminders in your language.',
            style: TextStyle(color: AppTheme.ink60, fontSize: 15, height: 1.4)),
        const SizedBox(height: 32),
        for (final lang in AppLanguage.values) ...[
          _LanguageTile(
            lang: lang,
            selected: _language == lang,
            onTap: () => setState(() => _language = lang),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildProfileStep() {
    final l = AppLocalizations(_language);
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Your details', style: _titleStyle()),
        const SizedBox(height: 8),
        Text('Tell us a bit about yourself so we can personalise your care.',
            style: TextStyle(color: AppTheme.ink60, fontSize: 15, height: 1.4)),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l.t('fullName'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionsStep(AppState app) {
    final l = AppLocalizations(_language);
    return Column(
      key: const ValueKey('conditions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Conditions you manage', style: _titleStyle()),
        const SizedBox(height: 8),
        Text('Select all that apply. We\'ll create a personalised medication schedule for each.',
            style: TextStyle(color: AppTheme.ink60, fontSize: 15, height: 1.4)),
        const SizedBox(height: 24),
        for (final c in ConditionType.values) ...[
          _ConditionTile(
            condition: c,
            selected: _conditions.contains(c),
            onTap: () => setState(() {
              if (_conditions.contains(c)) {
                _conditions.remove(c);
              } else {
                _conditions.add(c);
              }
            }),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _loading ? null : () => _useDemo(app),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(l.t('exploreDemo')),
        ),
      ],
    );
  }

  Widget _buildBottomActions(AppState app) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: const Text('Back'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _step < 2
                ? FilledButton(
                    onPressed: () => setState(() => _step++),
                    child: const Text('Continue'),
                  )
                : FilledButton(
                    onPressed: (_loading || _conditions.isEmpty)
                        ? null
                        : () => _createProfile(app),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Get Started'),
                  ),
          ),
        ],
      ),
    );
  }

  TextStyle _titleStyle() => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppTheme.ink,
      );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFCBD5E1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppTheme.cardShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.language,
                color: selected ? Colors.white : AppTheme.ink60,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                lang.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.condition,
    required this.selected,
    required this.onTap,
  });

  final ConditionType condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.06) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFCBD5E1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: condition.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(condition.icon, color: condition.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                condition.label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
