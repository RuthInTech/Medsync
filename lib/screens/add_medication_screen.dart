import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/medication.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController(text: '1 tablet');
  final _instructionsCtrl = TextEditingController();

  ConditionType? _condition;
  ProofMethod _proofMethod = ProofMethod.tap;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _loading = false;
  String? _error;

  List<ConditionType> get _patientConditions {
    final app = context.read<AppState>();
    return app.patient?.conditions ?? ConditionType.values;
  }

  @override
  void initState() {
    super.initState();
    final conditions = context.read<AppState>().patient?.conditions ?? [];
    if (conditions.isNotEmpty) _condition = conditions.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _times.add(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condition == null) {
      setState(() => _error = 'Please select a condition.');
      return;
    }
    if (_times.isEmpty) {
      setState(() => _error = 'Add at least one dose time.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final token = await AuthService().getToken();
      final api = ApiService(token: token);

      final scheduleTimes = _times
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList();

      final data = await api.post('/medications/', {
        'name': _nameCtrl.text.trim(),
        'condition': _condition!.name,
        'dosage_amount': _dosageCtrl.text.trim(),
        'schedule_times': scheduleTimes,
        'proof_method': _proofMethod.name,
        'window_minutes': 60,
        'instructions': _instructionsCtrl.text.trim(),
      });

      // Build local Medication from API response
      final med = Medication(
        id: data['id'].toString(),
        name: data['name'] as String,
        condition: _condition!,
        dosageAmount: data['dosage_amount'] as String,
        scheduleTimes: (_times.map((t) => DoseTime(t.hour, t.minute)).toList()),
        proofMethod: _proofMethod,
        windowMinutes: data['window_minutes'] as int,
        instructions: data['instructions'] as String? ?? '',
      );

      if (!mounted) return;
      await context.read<AppState>().addMedication(med);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = 'Could not save medication: ${e.message}');
    } catch (_) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add medication', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card([
              _label('Medication name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Metformin',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
            ]),
            const SizedBox(height: 16),
            _card([
              _label('Condition'),
              const SizedBox(height: 8),
              ..._patientConditions.map((c) => RadioListTile<ConditionType>(
                    value: c,
                    groupValue: _condition,
                    onChanged: (v) => setState(() => _condition = v),
                    title: Text(c.label,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    secondary: Icon(c.icon, color: c.color, size: 20),
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                  )),
            ]),
            const SizedBox(height: 16),
            _card([
              _label('Dosage amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. 500 mg',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Dosage is required' : null,
              ),
            ]),
            const SizedBox(height: 16),
            _card([
              Row(
                children: [
                  Expanded(child: _label('Dose times')),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add time'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_times.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No times set — tap Add time',
                      style: TextStyle(color: AppTheme.ink60, fontSize: 13)),
                )
              else
                ..._times.asMap().entries.map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.schedule, color: AppTheme.primary, size: 18),
                      ),
                      title: Text(e.value.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: _times.length > 1
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppTheme.ink60),
                              onPressed: () => setState(() => _times.removeAt(e.key)),
                            )
                          : null,
                    )),
            ]),
            const SizedBox(height: 16),
            _card([
              _label('Verification method'),
              const SizedBox(height: 8),
              ...ProofMethod.values.map((m) => RadioListTile<ProofMethod>(
                    value: m,
                    groupValue: _proofMethod,
                    onChanged: (v) => setState(() => _proofMethod = v!),
                    title: Text(m.label,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    secondary: Icon(m.icon, size: 20, color: AppTheme.primary),
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                  )),
            ]),
            const SizedBox(height: 16),
            _card([
              _label('Instructions (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructionsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Take with food',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 12),
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
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save medication'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink60));
}
