import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatefulWidget {
  final Function(Category?) onCategorySelected;

  const ExpensePieChart({super.key, required this.onCategorySelected});

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
    final sections = _buildPieChartSections(_categories);
    bool _clicked = false;

    return AspectRatio(
      aspectRatio: 1.5,
      child: sections.isNotEmpty
          ? PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent) {
                      final touchedSection = pieTouchResponse!.touchedSection;
                      if (touchedSection != null) {
                        // Access the category information from the touchedSection
                        final categoryIndex =
                            touchedSection.touchedSectionIndex;
                        final clickedCategory = _categories[categoryIndex];

                        _clicked = !_clicked;
                        if (_clicked) {
                          widget.onCategorySelected(clickedCategory);
                        } else {
                          widget.onCategorySelected(null);
                        }
                      }
                    }
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 16,
                sections: sections,
              ),
            )
          : const SizedBox(
              // Display a message or alternative widget when there's no data
              height: 0, width: 0,
            ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<Category> categories) {
    final totalExpense = categories.fold<double>(0,
        (previousValue, element) => previousValue + (element.expense as num));

    // Check if total expense is greater than zero
    if (totalExpense > 0) {
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
    } else {
      // If total expense is zero, return an empty list
      return [];
    }
  }
}
