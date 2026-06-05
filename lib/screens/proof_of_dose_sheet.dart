import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/medication.dart';

/// Presents the Proof-of-Dose verification flow as a modal bottom sheet and
/// returns the [ProofMethod] the patient used, or null if they cancelled.
///
/// The flow is two-step: choose a method, then perform a real capture — a tap,
/// an actual camera photo (`image_picker`), or a live QR / barcode scan
/// (`mobile_scanner`). A dose is only marked taken after an explicit,
/// method-specific confirmation, which is what makes the captured data
/// trustworthy.
Future<ProofMethod?> showProofOfDose(
  BuildContext context, {
  required Medication medication,
  required AppLanguage language,
}) {
  return showModalBottomSheet<ProofMethod>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ProofSheet(medication: medication, language: language),
  );
}

class _ProofSheet extends StatefulWidget {
  const _ProofSheet({required this.medication, required this.language});

  final Medication medication;
  final AppLanguage language;

  @override
  State<_ProofSheet> createState() => _ProofSheetState();
}

class _ProofSheetState extends State<_ProofSheet> {
  late ProofMethod _selected;
  bool _busy = false;
  XFile? _photo;

  @override
  void initState() {
    super.initState();
    _selected = widget.medication.proofMethod;
  }

  Future<void> _capture() async {
    switch (_selected) {
      case ProofMethod.tap:
        _finish();
      case ProofMethod.photo:
        await _capturePhoto();
      case ProofMethod.qrScan:
        await _scanCode();
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _busy = true);
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted) return;
      if (shot == null) {
        setState(() => _busy = false); // user backed out of the camera
        return;
      }
      setState(() {
        _photo = shot;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Camera unavailable: $e');
    }
  }

  Future<void> _scanCode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    if (!mounted || code == null) return;
    _finish();
  }

  void _finish() {
    Navigator.of(context).pop(_selected);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFD7263D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(widget.language);
    final med = widget.medication;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: med.condition.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(med.condition.icon, color: med.condition.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.t('confirmDose'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${med.name} · ${med.dosageAmount}',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          if (med.instructions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(med.instructions,
                          style: TextStyle(color: Colors.grey.shade700))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_photo != null)
            _PhotoConfirm(
              photo: _photo!,
              onRetake: () => setState(() => _photo = null),
            )
          else ...[
            Text(l.t('proofPrompt'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (final m in ProofMethod.values)
              _MethodTile(
                method: m,
                selected: _selected == m,
                onTap: _busy ? null : () => setState(() => _selected = m),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : (_photo != null ? _finish : _capture),
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : Icon(_photo != null ? Icons.check_circle : _selected.icon),
            label: Text(_busy
                ? 'Opening camera…'
                : (_photo != null ? l.t('takeDose') : _actionLabel(l))),
          ),
        ],
      ),
    );
  }

  String _actionLabel(AppLocalizations l) {
    switch (_selected) {
      case ProofMethod.tap:
        return l.t('takeDose');
      case ProofMethod.photo:
        return 'Take photo';
      case ProofMethod.qrScan:
        return 'Scan code';
    }
  }
}

class _PhotoConfirm extends StatelessWidget {
  const _PhotoConfirm({required this.photo, required this.onRetake});

  final XFile photo;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF2A9D8F), size: 18),
            SizedBox(width: 6),
            Text('Photo captured',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(photo.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retake'),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile(
      {required this.method, required this.selected, required this.onTap});

  final ProofMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? scheme.primary : Colors.grey.shade300,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(method.icon,
                  color: selected ? scheme.primary : Colors.grey.shade700),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(method.label,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              if (selected) Icon(Icons.check_circle, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen live QR / barcode scanner. Pops with the first decoded value.
class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan medication code'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Reticle to guide the patient.
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            bottom: 48,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point the camera at the pack QR / barcode',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
