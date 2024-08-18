import 'package:fintracker/theme/colors.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseLineChart extends StatelessWidget {
  final List<double> monthlyExpenses;

  ExpenseLineChart({
    super.key,
    required this.monthlyExpenses,
    Color? line1Color,
    Color? line2Color,
    Color? betweenColor,
  })  : line1Color = line1Color ?? ThemeColors.success,
        line2Color = line2Color ?? ThemeColors.error,
        betweenColor = betweenColor ?? ThemeColors.error.withOpacity(0.5);

  final Color line1Color;
  final Color line2Color;
  final Color betweenColor;

  double getYInterval(double maxExpense) {
    double step = maxExpense / 5; // Number of intervals
    double interval = (step / 10).ceil() * 10; // Round to nearest 10

    // Ensure interval is not zero
    return interval > 0 ? interval : 10; // Default to 10 if interval is zero
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Jan';
        break;
      case 1:
        text = 'Feb';
        break;
      case 2:
        text = 'Mar';
        break;
      case 3:
        text = 'Apr';
        break;
      case 4:
        text = 'May';
        break;
      case 5:
        text = 'Jun';
        break;
      case 6:
        text = 'Jul';
        break;
      case 7:
        text = 'Aug';
        break;
      case 8:
        text = 'Sep';
        break;
      case 9:
        text = 'Oct';
        break;
      case 10:
        text = 'Nov';
        break;
      case 11:
        text = 'Dec';
        break;
      default:
        return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: CurrencyText(
        value,
        overflow: TextOverflow.fade, // Changed to ellipsis to handle overflow
        style: const TextStyle(
          fontSize: 10, // Adjusted font size for better visibility
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyExpenses.isEmpty) {
      return Center(child: Text('No expenses data available'));
    }

    double maxExpense = monthlyExpenses.reduce((a, b) => a > b ? a : b);
    double interval = getYInterval(maxExpense);

    return AspectRatio(
      aspectRatio: 2,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16, // Increased padding to provide more space for the Y-axis labels
          right: 18,
          top: 10,
          bottom: 8, // Increased bottom padding for better spacing
        ),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '\$${spot.y}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(12, (index) {
                  return FlSpot(index.toDouble(), monthlyExpenses[index]);
                }),
                isCurved: true,
                barWidth: 2,
                color: line1Color,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: line1Color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            ],
            minY: 0,
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.black, width: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: bottomTitleWidgets,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: leftTitleWidgets,
                  interval: interval,
                  reservedSize: 50, // Increased reserved size for Y-axis titles
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(
              show: false,
            ),
          ),
        ),
      ),
    );
  }
}
