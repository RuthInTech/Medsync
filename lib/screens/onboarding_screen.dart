import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../theme.dart';

/// First-run onboarding: language, identity, and the patient's chronic
/// conditions. Offers a guided custom setup or a fully-seeded demo profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '40');
  AppLanguage _language = AppLanguage.english;
  final Set<ConditionType> _conditions = {ConditionType.diabetes};

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// Default starter regimen for a condition (one medication, sensible times).
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
  }

  Future<void> _useDemo(AppState app) async {
    final demo = SeedData.demoPatient()..language = _language;
    await app.onboard(demo, history: SeedData.demoHistory(demo));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l = AppLocalizations(_language);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E6E7C).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.health_and_safety,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Text(l.t('appName'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.t('welcomeBody'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 15, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _label(l.t('language')),
            Wrap(
              spacing: 8,
              children: [
                for (final lang in AppLanguage.values)
                  ChoiceChip(
                    label: Text(lang.label),
                    selected: _language == lang,
                    onSelected: (_) => setState(() => _language = lang),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _label('Your details'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _label('Conditions you manage'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in ConditionType.values)
                  FilterChip(
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.label),
                    selected: _conditions.contains(c),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _conditions.add(c);
                      } else {
                        _conditions.remove(c);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _conditions.isEmpty
                  ? null
                  : () => _createProfile(app),
              child: Text(l.t('getStarted')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _useDemo(app),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Explore demo profile (with history)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );
}
