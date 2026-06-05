import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Compact colored pill conveying a risk tier.
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.tier, this.score});

  final RiskTier tier;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final label = score == null
        ? tier.label
        : '${tier.label} · ${score!.round()}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: tier.color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tier.color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
