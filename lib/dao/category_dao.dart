import 'dart:async';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryDao {
  Future<int> create(Category category) async {
    final db = await getDBInstance();
    var result = db.insert("categories", category.toJson());
    return result;
  }
Future<List<Category>> find({bool withSummery = true, DateTimeRange? range}) async {
  final db = await getDBInstance();
  List<Map<String, dynamic>> result;

  // Use the provided DateTimeRange, or default to the current month if null
  DateTime from = range?.start ??
      DateTime(DateTime.now().year, DateTime.now().month, 1, 0, 0);
  DateTime to = range?.end ?? DateTime.now().add(const Duration(days: 1));

  // If a single day is selected, adjust 'to' to be the end of that day
  if (from == to) {
    to = DateTime(to.year, to.month, to.day, 23, 59, 59);
  }

  if (withSummery) {
    String fields = [
      "c.id",
      "c.name",
      "c.icon",
      "c.color",
      "c.budget",
      "SUM(CASE WHEN t.type='DR' AND t.category=c.id THEN t.amount END) as expense"
    ].join(",");

    DateFormat formatter = DateFormat("yyyy-MM-dd HH:mm");
    String sql = "SELECT $fields FROM categories c "
        "LEFT JOIN payments t ON t.category = c.id AND t.datetime BETWEEN '${formatter.format(from)}' AND '${formatter.format(to)}' "
        "GROUP BY c.id";

    result = await db.rawQuery(sql);
  } else {
    result = await db.query("categories");
  }

  List<Category> categories = [];
  if (result.isNotEmpty) {
    categories = result.map((item) => Category.fromJson(item)).toList();
  }

  return categories;
}

  Future<int> update(Category category) async {
    final db = await getDBInstance();

    var result = await db.update("categories", category.toJson(),
        where: "id = ?", whereArgs: [category.id]);

    return result;
  }

  Future<int> upsert(Category category) {
    if (category.id != null) {
      return update(category);
    } else {
      return create(category);
    }
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    var result =
        await db.delete("categories", where: 'id = ?', whereArgs: [id]);
    return result;
  }

  Future deleteAll() async {
    final db = await getDBInstance();
    var result = await db.delete(
      "categories",
    );
    return result;
  }

  Future<Category?>? findCategoryById(int id) async {
    final db = await getDBInstance();
    final List<Map<String, dynamic>> categories = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id], // Assuming you want to filter for true
    );
    if (categories.isNotEmpty) {
      return Category.fromJson(categories[0]);
    }
    return null;
  }
}
