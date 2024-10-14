import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferncesHelper {
  static late SharedPreferences prefs;

  static initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    debugPrint("Intitialized SharedPrefernces");
  }

  static SharedPreferences getPrefsInstance() {
    return prefs;
  }

  static storeUserRules(List<String> listOfTitleRules,
      Map<String, dynamic> listOfCategoryRules) async {
    await prefs.setStringList("userTitleRules", listOfTitleRules);
    debugPrint("Stored userTitle Rules as : $listOfTitleRules");

    await prefs.setString(
      'userCategoryRules',
      jsonEncode(listOfCategoryRules),
    );
    debugPrint("Stored userCategory Rules as : $listOfCategoryRules");
  }

  static List<String> getListOfUserRules() {
    return prefs.getStringList('userTitleRules') ?? [];
  }

  static Map<String, dynamic> getListOfCategoryRules() {
    String map = prefs.getString("userCategoryRules") ?? "";
    if (map.isNotEmpty) {
      Map<String, dynamic> ans = jsonDecode(map);
      return ans;
    }
    return {};
  }

  static void remove(String title) {
    Map<String, dynamic> listOfCategories = getListOfCategoryRules();
    List<String> listOfUserRules = getListOfUserRules();
    listOfCategories.removeWhere((key, value) => key == title);
    listOfUserRules.removeWhere((element) => element == title);
    storeUserRules(listOfUserRules, listOfCategories);
  }
}
