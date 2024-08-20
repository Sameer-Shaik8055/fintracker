import 'dart:async';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/helpers/sharedpreferneceshelper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PaymentDao {
  Future<int> create(Payment payment) async {
    final db = await getDBInstance();
    var result = db.insert("payments", payment.toJson());
    return result;
  }

  Future<List<Payment>> find({
    DateTimeRange? range,
    PaymentType? type,
    Category? category,
    Account? account
}) async {
    final db = await getDBInstance();
    String where = "";

    if(range!=null){
      where += "AND datetime BETWEEN DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.start)}') AND DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.end.add(const Duration(days: 1)))}')";
    }

    //type check
    if(type != null){
      where += "AND type='${type == PaymentType.credit?"DR":"CR"}' ";
    }

    //icon check
    if(account != null){
      where += "AND account='${account.id}' ";
    }

    //icon check
    if(category != null){
      where += "AND category='${category.id}' ";
    }

    //categories
    List<Category> categories = await CategoryDao().find();
    List<Account> accounts = await AccountDao().find();


    List<Payment> payments = [];
    List<Map<String, Object?>> rows =  await db.query(
        "payments",
        orderBy: "datetime DESC, id DESC",
        where: "1=1 $where"
    );
    for (var row in rows) {
      Map<String, dynamic> payment = Map<String, dynamic>.from(row);
      Account account = accounts.firstWhere((a) => a.id == payment["account"]);
      Category category = categories.firstWhere((c) => c.id == payment["category"]);
      payment["category"] = category.toJson();
      payment["account"] = account.toJson();
      payment['autoCategorizationEnabled'] = payment['autoCategorizationEnabled'] == 0 ? false : true;
      payments.add(Payment.fromJson(payment));
    }

    return payments;
  }

  Future<int> update(Payment payment) async {
    final db = await getDBInstance();

    var result = await db.update("payments", payment.toJson(), where: "id = ?", whereArgs: [payment.id]);

    return result;
  }

  Future<int> upsert(Payment payment) async {
    final db = await getDBInstance();
    int result;
    if(payment.id != null) {
      result = await db.update(
          "payments", payment.toJson(), where: "id = ?",
          whereArgs: [payment.id]);
    } else {
      result = await db.insert("payments", payment.toJson());
    }

    return result;
  }


  Future<int> deleteTransaction(int id) async {
    final db = await getDBInstance();
    var result = await db.delete("payments", where: 'id = ?', whereArgs: [id]);
    return result;
  }

  Future deleteAllTransactions() async {
    final db = await getDBInstance();
    var result = await db.delete(
      "payments",
    );
    return result;
  }

  Future<int> findPaymentCategoryByTitle(String title) async {
    final db = await getDBInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'title = ? AND autoCategorizationEnabled = ?',
      whereArgs: [title, true], // Assuming you want to filter for true
    );
    if (maps.isNotEmpty) {

      // Returns the Index of Applied Category
      return (maps.first)['category']-1;
    }
    return 9;
  }

  Future<List<Map<String,dynamic>>?> findPaymentsWithMissingCategory() async {
    final db = await getDBInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'category = ?',
      whereArgs: [9], // Assuming you want to filter for true
    );
    if (maps.isNotEmpty) {
      return maps;
    }
    return null;
  }

  Future<Map<String,dynamic>?> searchForSameTitle(String title,int id) async{
    final db = await getDBInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'title = ? AND id != ?',
      whereArgs: [title,id], // Assuming you want to filter for true
    );

    if(maps.isNotEmpty){
      return maps.first;
    }

    return null;
  }


  Future<List<Map<String,dynamic>>?> getAllMiscellanous() async{

    List<Category> allCategories = await CategoryDao().find();
    final db = await getDBInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'category = ?',
      whereArgs: [10], // Assuming you want to filter for true
    );

    if(maps.isNotEmpty){
      return maps;
    }

    return null;
  }


  Future<int> updateMiscellanousCategories() async{

    int count = 0;
    CategoryDao categoryDao = CategoryDao();
    AccountDao accountDao = AccountDao();
    List<Map<String,dynamic>> allMisPayments = await getAllMiscellanous() ?? [];
    if(allMisPayments.isNotEmpty){

      for(Map<String,dynamic> misPayment in allMisPayments){
        Map<String,dynamic> gotPayment = await searchForSameTitle(misPayment['title'], misPayment['id']) ?? {};
        if(gotPayment.isNotEmpty){
          Category? cat = await categoryDao.findCategoryById(gotPayment['category']);
          Account? acc = await accountDao.findCategoryById(misPayment['account']);
          final updatedMap = {"id": misPayment['id'], "title": misPayment['title'], "description": misPayment['description'], "account": acc!.toJson(), "category": cat!.toJson(), "amount": misPayment['account'].toDouble(), "type": misPayment['type'], "datetime": misPayment['datetime'], "autoCategorizationEnabled": misPayment['autoCategorizationEnabled'] == 1 ? true : false};
          await upsert(Payment.fromJson(updatedMap),);
          count++;
        }
      }

    }
    return count;
  }

  Future<int> categorizeUsingRules()async{

    CategoryDao categoryDao = CategoryDao();
    AccountDao accountDao = AccountDao();
    final db = await getDBInstance();
    List<String> titles = [
      "Toll charges",
      "Motors",
      "Food",
      "Swiggy",
      "Zomato",
      "Bistro",
      "Restaurant",
      "pharmacy",
      "Diagnostics",
      "BookMyShow"
    ];

    Map<String,dynamic> mapOfCategory = SharedPreferncesHelper.getListOfCategoryRules();
    List<String> getUserRules = SharedPreferncesHelper.getListOfUserRules();
    titles.addAll(getUserRules);

// Get User Defined Rules using below line
// List userRules = await getUserRules();
// titles.addAll(userRules);

    String placeholders = List.generate(titles.length, (index) => '?').join(',');

    final upperTitles = titles.map((title) => title.toUpperCase()).toList();

    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'UPPER(title) IN ($placeholders) AND category = ?',
      whereArgs: [...upperTitles,10],
    );

    int count = 0;

    for(Map<String,dynamic> payment in maps){
      String title = payment['title'].toLowerCase();

      //Transportation Category
      if(title == "toll charges" || title == "motors"){
        Category? category = await categoryDao.findCategoryById(2);
        Account? account = await accountDao.findCategoryById(payment['account']);
        final updatedMap = {"id": payment['id'], "title": payment['title'], "description": payment['description'], "account": account!.toJson(), "category": category!.toJson(), "amount": payment['account'].toDouble(), "type": payment['type'], "datetime": payment['datetime'], "autoCategorizationEnabled": payment['autoCategorizationEnabled'] == 1 ? true : false};
        await upsert(Payment.fromJson(updatedMap),);
        count++;
      }


      //Food Category
      else if(title == "food" || title == "swiggy" || title == "zomato" || title == "bistro" || title == "restaurant"){
        Category? category = await categoryDao.findCategoryById(3);
        Account? account = await accountDao.findCategoryById(payment['account']);
        final updatedMap = {"id": payment['id'], "title": payment['title'], "description": payment['description'], "account": account!.toJson(), "category": category!.toJson(), "amount": payment['account'].toDouble(), "type": payment['type'], "datetime": payment['datetime'], "autoCategorizationEnabled": payment['autoCategorizationEnabled'] == 1 ? true : false};
        await upsert(Payment.fromJson(updatedMap),);
        count++;
      }


      //Medical and Healthcare Category
      else if(title == "pharmacy" || title=="diagnostics"){
        Category? category = await categoryDao.findCategoryById(6);
        Account? account = await accountDao.findCategoryById(payment['account']);
        final updatedMap = {"id": payment['id'], "title": payment['title'], "description": payment['description'], "account": account!.toJson(), "category": category!.toJson(), "amount": payment['account'].toDouble(), "type": payment['type'], "datetime": payment['datetime'], "autoCategorizationEnabled": payment['autoCategorizationEnabled'] == 1 ? true : false};
        await upsert(Payment.fromJson(updatedMap),);
        count++;
      }

      else if(title == "bookmyshow"){
        Category? category = await categoryDao.findCategoryById(9);
        Account? account = await accountDao.findCategoryById(payment['account']);
        final updatedMap = {"id": payment['id'], "title": payment['title'], "description": payment['description'], "account": account!.toJson(), "category": category!.toJson(), "amount": payment['account'].toDouble(), "type": payment['type'], "datetime": payment['datetime'], "autoCategorizationEnabled": payment['autoCategorizationEnabled'] == 1 ? true : false};
        await upsert(Payment.fromJson(updatedMap),);
        count++;
      }

      else if(mapOfCategory.containsKey(title)) {
          int categoryInt = mapOfCategory[title];
          Category? category = await categoryDao.findCategoryById(categoryInt);
          Account? account = await accountDao.findCategoryById(
              payment['account']);
          final updatedMap = {
            "id": payment['id'],
            "title": payment['title'],
            "description": payment['description'],
            "account": account!.toJson(),
            "category": category!.toJson(),
            "amount": payment['account'].toDouble(),
            "type": payment['type'],
            "datetime": payment['datetime'],
            "autoCategorizationEnabled": payment['autoCategorizationEnabled'] ==
                1 ? true : false
          };
          await upsert(Payment.fromJson(updatedMap),);
          count++;
        }

    }

    return count;
  }

}