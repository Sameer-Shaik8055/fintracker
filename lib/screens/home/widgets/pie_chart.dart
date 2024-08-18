import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:events_emitter/events_emitter.dart';

class ExpensePieChart extends StatefulWidget {
  final Function(Category?) onCategorySelected;

  const ExpensePieChart({super.key, required this.onCategorySelected});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  final CategoryDao _categoryDao = CategoryDao();
  List<Category> _categories = [];
  List<int> _sectionToCategoryIndex = [];
  EventListener? _paymentEventListener;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchData();

    // Add event listener for payment updates
    _paymentEventListener = globalEvent.on("payment_update", (data) {
      debugPrint("payments are changed, updating pie chart");
      _fetchData();
    });
  }

  @override
  void dispose() {
    _paymentEventListener?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    List<Category> categories = await _categoryDao.find(withSummery: true);

    setState(() {
      _categories = categories;
      _sectionToCategoryIndex = _buildSectionToCategoryIndex(categories);
    });
  }

  List<int> _buildSectionToCategoryIndex(List<Category> categories) {
    List<int> sectionToCategoryIndex = [];
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].expense! > 0) {
        sectionToCategoryIndex.add(i);
      }
    }
    return sectionToCategoryIndex;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildPieChartSections(_categories);

    return AspectRatio(
      aspectRatio: 1.5,
      child: sections.isNotEmpty
          ? PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent) {
                      final touchedSection = pieTouchResponse?.touchedSection;
                      if (touchedSection != null) {
                        final sectionIndex = touchedSection.touchedSectionIndex;
                        final categoryIndex = _sectionToCategoryIndex[sectionIndex];
                        final clickedCategory = _categories[categoryIndex];
                        print('Selected category: ${clickedCategory.name}');

                        setState(() {
                          if (_selectedCategory == clickedCategory) {
                            _selectedCategory = null; // Clear filter
                            widget.onCategorySelected(null);
                          } else {
                            _selectedCategory = clickedCategory; // Set filter
                            widget.onCategorySelected(clickedCategory);
                          }
                        });
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
              height: 0,
              width: 0,
            ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<Category> categories) {
    final totalExpense = categories.fold<double>(0,
        (previousValue, element) => previousValue + (element.expense as num));

    // Check if total expense is greater than zero
    if (totalExpense > 0) {
      final nonZeroCategories = categories.where((category) => category.expense! > 0).toList();

      return nonZeroCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final percentage = (category.expense! / totalExpense) * 100;

        // Debug logging to check category order and values
        print('Category: ${category.name}, Index: $index, Percentage: $percentage');

        return PieChartSectionData(
          color: category.color,
          value: percentage,
          title: percentage > 5
              ? '${percentage.toStringAsFixed(0)}%\n${category.expense}'
              : "",
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
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
