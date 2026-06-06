import 'package:flutter/material.dart';

import '../models/dose_event.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../theme.dart';

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
    final isTaken = event.status == DoseStatus.taken;
    final isMissed = event.status == DoseStatus.missed || event.status == DoseStatus.ignored;

    Color cardBg = AppTheme.surface;
    if (isTaken) cardBg = const Color(0xFFF0FDF4);
    if (isMissed) cardBg = const Color(0xFFFFF1F2);
    if (isDue) cardBg = const Color(0xFFF0F7FF);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: isDue
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5)
            : isTaken
                ? Border.all(color: AppTheme.secondary.withValues(alpha: 0.3))
                : isMissed
                    ? Border.all(color: AppTheme.error.withValues(alpha: 0.2))
                    : Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: c.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 12, color: AppTheme.ink60),
                    const SizedBox(width: 4),
                    Text(
                      '${medication.dosageAmount} · $time',
                      style: const TextStyle(color: AppTheme.ink60, fontSize: 12.5),
                    ),
                  ],
                ),
                if (isDue) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Due now',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
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
            minimumSize: const Size(80, 38),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          child: const Text('Take'),
        );
      case DoseStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Later',
              style: TextStyle(
                  color: AppTheme.ink60,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
        );
      case DoseStatus.taken:
        return _statusChip(Icons.check_circle_rounded, AppTheme.secondary, 'Taken');
      case DoseStatus.late:
        return _statusChip(Icons.check_circle_outline, AppTheme.warning, 'Late');
      case DoseStatus.missed:
        return _statusChip(Icons.cancel_outlined, AppTheme.error, 'Missed');
      case DoseStatus.ignored:
        return _statusChip(Icons.notifications_off_outlined, AppTheme.error, 'Ignored');
    }
  }

  Widget _statusChip(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
