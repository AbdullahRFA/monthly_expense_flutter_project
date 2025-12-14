import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../expenses/domain/expense_model.dart';
import '../../../core/utils/expense_grouper.dart';

class SpendingTrendChart extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const SpendingTrendChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // 1. Group Data by Day
    final grouped = ExpenseGrouper.groupExpensesByDate(expenses);
    final sortedKeys = grouped.keys.toList()..sort();

    // Show last 7 active days for better visibility (or all if less)
    final displayKeys = sortedKeys.length > 7 ? sortedKeys.sublist(sortedKeys.length - 7) : sortedKeys;

    if (displayKeys.isEmpty) return const SizedBox.shrink();

    double maxY = 0;
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < displayKeys.length; i++) {
      final key = displayKeys[i];
      final dayExpenses = grouped[key]!;

      // Calculate total spending for this day (Ignoring negative "Income")
      final dailyTotal = dayExpenses
          .where((e) => e.amount > 0)
          .fold(0.0, (sum, e) => sum + e.amount);

      if (dailyTotal > maxY) maxY = dailyTotal;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyTotal,
              color: Colors.teal,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Daily Trend (Last 7 Active Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2, // Add headroom
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final key = displayKeys[group.x.toInt()];
                        final date = DateTime.parse(key);
                        return BarTooltipItem(
                          "${DateFormat('MMM d').format(date)}\n",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: rod.toY.toStringAsFixed(0),
                              style: const TextStyle(color: Colors.yellow),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= displayKeys.length) return const SizedBox();

                          final date = DateTime.parse(displayKeys[index]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('d').format(date), // Day number (e.g., 12)
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}