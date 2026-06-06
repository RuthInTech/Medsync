import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/patient.dart';
import '../services/api_service.dart';
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
  final _ageController = TextEditingController(text: '30');
  AppLanguage _language = AppLanguage.english;
  final Set<ConditionType> _conditions = {};
  bool _loading = false;
  String? _error;
  int _step = 0; // 0 = language, 1 = age + conditions

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _finish(AppState app) async {
    if (_conditions.isEmpty) {
      setState(() => _error = 'Please select at least one condition.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final auth = AuthService();
      final token = await auth.getToken();
      final name = await auth.getName() ?? 'Patient';
      final age = int.tryParse(_ageController.text.trim()) ?? 30;
      final conditionNames = _conditions.map((c) => c.name).toList();

      // Sync profile to backend
      final api = ApiService(token: token);
      await api.put('/patients/me', {
        'name': name,
        'age': age,
        'conditions': conditionNames,
        'language': _language.code,
        'is_onboarded': true,
      });

      // Set up local app state with empty medication list
      final patient = PatientProfile(
        id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        age: age,
        language: _language,
        conditions: _conditions.toList(),
        medications: [],
      );
      await app.onboard(patient);
      await auth.setOnboarded();
      widget.onComplete?.call();
    } on ApiException catch (e) {
      setState(() => _error = 'Could not save profile: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
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
                  child: _step == 0 ? _buildLanguageStep() : _buildProfileStep(),
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
                'Medisync',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i <= _step ? AppTheme.primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_step + 1} of 2',
            style: TextStyle(color: AppTheme.ink60, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    return Column(
      key: const ValueKey('lang'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text('Choose your language',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 8),
        Text("We'll show medication info and reminders in your language.",
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
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text('About you',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 8),
        Text('Tell us your age and the conditions you manage.',
            style: TextStyle(color: AppTheme.ink60, fontSize: 15, height: 1.4)),
        const SizedBox(height: 24),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Conditions you manage',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        Text("Select all that apply. You'll add your medications after setup.",
            style: TextStyle(color: AppTheme.ink60, fontSize: 13, height: 1.4)),
        const SizedBox(height: 14),
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
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ],
            ),
          ),
        ],
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
          if (_step > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _loading ? null : () => setState(() { _step--; _error = null; }),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: _step == 0
                ? FilledButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Continue'),
                  )
                : FilledButton(
                    onPressed: _loading ? null : () => _finish(app),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Get Started'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.lang, required this.selected, required this.onTap});
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
              child: Icon(Icons.language,
                  color: selected ? Colors.white : AppTheme.ink60, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(lang.label,
                  style: TextStyle(
                      color: selected ? Colors.white : AppTheme.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({required this.condition, required this.selected, required this.onTap});
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
              child: Text(condition.label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }
}
