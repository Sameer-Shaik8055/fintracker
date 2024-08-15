import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({super.key});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  final CategoryDao _categoryDao = CategoryDao();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    List<Category> categories = await _categoryDao.find(withSummery: true);

    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Handle touch events if needed
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 16,
          sections: _buildPieChartSections(_categories),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<Category> categories) {
    final totalExpense = categories.fold<double>(0,
        (previousValue, element) => previousValue + (element.expense as num));

    return categories.map((category) {
      final percentage = (category.expense! / totalExpense) * 100;
      return PieChartSectionData(
        color: category.color,
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%\n${category.expense}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Container(
          width: 34, // Adjust the size as needed
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: category.color,
          ),
          child: Icon(
            category.icon,
            color: Colors.white, // Adjust icon color if needed
            size: 18, // Adjust icon size as needed
          ),
        ),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }
}
