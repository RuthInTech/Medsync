import 'package:flutter/material.dart';

import '../models/dose_event.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../theme.dart';

/// A single dose row on the Today list, with a contextual action/state.
class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.event,
    required this.medication,
    required this.onTake,
  });

  final DoseEvent event;
  final Medication medication;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final c = medication.condition;
    final time = TimeOfDay.fromDateTime(event.scheduledFor).format(context);
    final isDue = event.status == DoseStatus.due;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: isDue
            ? Border.all(color: c.color.withValues(alpha: 0.45), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.color.withValues(alpha: 0.22),
                  c.color.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(c.icon, color: c.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${medication.dosageAmount} · $time',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          _trailing(context),
        ],
      ),
    );
  }

  Widget _trailing(BuildContext context) {
    switch (event.status) {
      case DoseStatus.due:
        return FilledButton(
          onPressed: onTake,
          style: FilledButton.styleFrom(
            minimumSize: const Size(92, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: const Text('Take'),
        );
      case DoseStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Soon',
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        );
      case DoseStatus.taken:
        return _statusChip(Icons.check_circle, const Color(0xFF2A9D8F), 'Taken');
      case DoseStatus.late:
        return _statusChip(
            Icons.check_circle_outline, const Color(0xFFE09F3E), 'Late');
      case DoseStatus.missed:
        return _statusChip(Icons.cancel, const Color(0xFFD7263D), 'Missed');
      case DoseStatus.ignored:
        return _statusChip(
            Icons.notifications_off, const Color(0xFFD7263D), 'Ignored');
    }
  }

  Widget _statusChip(IconData icon, Color color, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );
}
