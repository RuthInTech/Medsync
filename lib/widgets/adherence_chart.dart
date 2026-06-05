import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 7-day completion-rate bar chart (values 0.0–1.0).
class AdherenceChart extends StatelessWidget {
  const AdherenceChart({super.key, required this.weeklyRates});

  final List<double> weeklyRates;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final scheme = Theme.of(context).colorScheme;
    if (weeklyRates.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('No data yet')),
      );
    }
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: 1,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  final idx = i % labels.length;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[idx],
                        style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < weeklyRates.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: weeklyRates[i] == 0 ? 0.02 : weeklyRates[i],
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: _colorFor(weeklyRates[i], scheme),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Color _colorFor(double rate, ColorScheme scheme) {
    if (rate >= 0.99) return const Color(0xFF2A9D8F);
    if (rate >= 0.5) return const Color(0xFFE09F3E);
    return const Color(0xFFD7263D);
  }
}
