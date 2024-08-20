import 'package:fintracker/helpers/sharedpreferneceshelper.dart';
import 'package:fintracker/screens/settings/adduserrules.dart';
import 'package:flutter/material.dart';

import '../../dao/category_dao.dart';
import '../../model/category.model.dart';
import '../../widgets/dialog/category_form.dialog.dart';

class NewRulesScreen extends StatefulWidget {
  const NewRulesScreen({super.key});

  @override
  State<NewRulesScreen> createState() => _NewRulesScreenState();
}

class _NewRulesScreenState extends State<NewRulesScreen> {
  String title = "";
  List<Category> _categories = [];
  Category? _category;
  List<String> stringCateogires = [];
  CategoryDao categoryDao = CategoryDao();

  @override
  void initState() {
    super.initState();
    setCategories();
    setState(() {});
  }

  setCategories() async {
    categoryDao.find().then((value) {
      setState(() {
        _categories = value;
        for (var category in _categories) {
          stringCateogires.add(category.name);
        }
        _category = _categories[0];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Rule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Container(
              margin: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
              child: TextFormField(
                decoration: InputDecoration(
                    filled: true,
                    hintText: "Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 15)),
                initialValue: "",
                onChanged: (text) {
                  title = text;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 15, bottom: 15),
              child: const Text(
                "Select Category",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 25, left: 15, right: 15),
              width: double.infinity,
              child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_categories.length + 1, (index) {
                    if (_categories.length == index) {
                      return ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 0,
                          ),
                          child: IntrinsicWidth(
                            child: MaterialButton(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: const BorderSide(
                                        width: 1.5, color: Colors.transparent)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 0),
                                elevation: 0,
                                focusElevation: 0,
                                hoverElevation: 0,
                                highlightElevation: 0,
                                disabledElevation: 0,
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (builder) =>
                                          const CategoryForm());
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text("New Category",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  ),
                                )),
                          ));
                    }
                    Category category = _categories[index];
                    return ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 0,
                        ),
                        child: IntrinsicWidth(
                            child: MaterialButton(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                        width: 1.5,
                                        color: _category?.id == category.id
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 0),
                                elevation: 0,
                                focusElevation: 0,
                                hoverElevation: 0,
                                highlightElevation: 0,
                                disabledElevation: 0,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onPressed: () async {
                                  setState(() {
                                    _category = category;
                                  });
                                },
                                onLongPress: () {
                                  showDialog(
                                      context: context,
                                      builder: (builder) => CategoryForm(
                                            category: category,
                                          ));
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      Icon(category.icon,
                                          color: category.color),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        category.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ))));
                  })),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  save() {
    List<String> listOfUserRules = SharedPreferncesHelper.getListOfUserRules();
    Map<String, dynamic> listOfCategoryRules =
        SharedPreferncesHelper.getListOfCategoryRules();
    if (!listOfUserRules.contains(title)) {
      listOfUserRules.add(title);
    }
    listOfCategoryRules[title] = _category!.id!;
    SharedPreferncesHelper.storeUserRules(listOfUserRules, listOfCategoryRules);
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUserSettingsScreen(),
      ),
    );
  }
}
