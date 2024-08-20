import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/helpers/sharedpreferneceshelper.dart';
import 'package:fintracker/screens/settings/newrulescreen.dart';
import 'package:flutter/material.dart';

import '../../model/category.model.dart';
import '../../widgets/dialog/category_form.dialog.dart';

class AddUserSettingsScreen extends StatefulWidget {
  @override
  State<AddUserSettingsScreen> createState() => _AddUserSettingsScreenState();
}

class _AddUserSettingsScreenState extends State<AddUserSettingsScreen> {
  List<String> listOfUserRules = [];
  Map<String, dynamic> listOfCategoryRules = {};

  @override
  void initState() {
    super.initState();
    setData();
  }

  setData(){
    listOfCategoryRules = SharedPreferncesHelper.getListOfCategoryRules();
    listOfUserRules = SharedPreferncesHelper.getListOfUserRules();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Rules",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: listOfUserRules.isNotEmpty
          ? ListView.builder(
              itemCount: listOfUserRules.length,
              itemBuilder: (context, index) {
                String title = listOfUserRules[index];
                return ListTile(
                  title:  Text(title, style: Theme.of(context).textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle:  Text("Category : ${listOfCategoryRules[title]}",style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.grey, overflow: TextOverflow.ellipsis)),
                  trailing: IconButton(icon: Icon(Icons.delete,color: Colors.red,),onPressed: (){
                    SharedPreferncesHelper.remove(title);
                    setData();
                  },),
                );
              })
          : Center(
              child: Text("No Rules Defined Yet"),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> NewRulesScreen(),),),
        child: Icon(Icons.add),
      ),
    );
  }
}
