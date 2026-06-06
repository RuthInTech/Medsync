import 'package:flutter/material.dart';

import '../models/enums.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.tier, this.score});

  final RiskTier tier;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, borderColor) = switch (tier) {
      RiskTier.low => (
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
          const Color(0xFF6EE7B7),
        ),
      RiskTier.medium => (
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
          const Color(0xFFFCD34D),
        ),
      RiskTier.high => (
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
          const Color(0xFFFCA5A5),
        ),
    };

    final label = score == null
        ? tier.label
        : '${tier.label} · ${score!.round()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
