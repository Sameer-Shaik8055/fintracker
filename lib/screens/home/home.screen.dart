import 'package:events_emitter/events_emitter.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/home/widgets/date_picker.dart';
import 'package:fintracker/screens/home/widgets/line_chart.dart';
import 'package:fintracker/screens/home/widgets/pie_chart.dart';
import 'package:fintracker/screens/home/widgets/account_slider.dart';
import 'package:fintracker/screens/home/widgets/payment_list_item.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/theme/colors.dart';
import 'package:fintracker/widgets/currency.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

String greeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Morning';
  }
  if (hour < 17) {
    return 'Afternoon';
  }
  return 'Evening';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Account> _accounts = [];
  double _income = 0;
  double _expense = 0;
  List<double> _monthlyExpenses = List.generate(12, (index) => 0.0);
  Account? _selectedAccount;
  Category? _selectedCategory;

  //double _savings = 0;

  DateTime _focusDate = DateTime.now();

  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day - 1)),
      end: DateTime.now());
  Account? _account;
  Category? _category;
  bool _showingIncomeOnly = false; // New state variable
  bool _showingExpenseOnly = false;

  void openAddPaymentPage(PaymentType type) async {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (builder) => PaymentForm(type: type)));
  }

  void _updateDateRange(DateTimeRange newRange) {
    setState(() {
      _range = newRange;
      _fetchTransactions();
    });
  }

  void handleChooseDateRange() async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (builder) =>
            CustomCalender(updateDateRange: _updateDateRange)));
  }

  void _fetchTransactions() async {
    List<Payment> trans;

    // Filter based on showing income/expense only and selected account

    if (_selectedCategory == null) {
      trans = await _paymentDao.find(range: _range, category: _category);
    }
    if (_showingIncomeOnly) {
      trans = await _paymentDao.find(
        range: _range,
        type: PaymentType.debit,
        account:
            _selectedAccount ?? _account, // Use the selected account (optional)
        category: _selectedCategory, // Filter by selected category (mandatory)
      );
    } else if (_showingExpenseOnly) {
      trans = await _paymentDao.find(
        range: _range,
        type: PaymentType.credit,
        account:
            _selectedAccount ?? _account, // Use the selected account (optional)
        category: _selectedCategory, // Filter by selected category (mandatory)
      );
    } else {
      // If no filtering by income/expense
      if (_selectedCategory != null) {
        // Filter by category only if a category is selected
        trans = await _paymentDao.find(
          range: _range,
          category: _selectedCategory,
        );
      } else if (_selectedAccount != null) {
        // If no category selected, filter by account
        trans = await _paymentDao.find(
            range: _range,
            account: _selectedAccount // Use the selected account (optional)
            );
      } else {
        // If no filters applied, fetch all transactions (unchanged)
        trans = await _paymentDao.find(range: _range, category: _category);
      }
    }

    double income = 0;
    double expense = 0;
    List<double> monthlyExpenses = List.generate(12, (index) => 0.0);
    for (var payment in trans) {
      if (payment.type == PaymentType.credit) income += payment.amount;
      if (payment.type == PaymentType.debit) {
        expense += payment.amount;
        DateTime paymentDate = payment.datetime;
        monthlyExpenses[paymentDate.month - 1] += payment.amount;
      }
    }

    // fetch accounts
    List<Account> accounts = await _accountDao.find(withSummery: true);

    setState(() {
      _payments = trans;
      _income = income;
      _expense = expense;
      _accounts = accounts;
      _monthlyExpenses = monthlyExpenses;
    });
  }

  void onAccountSelected(Account? account) {
    setState(() {
      _selectedAccount = account;

      _fetchTransactions();
    });
  }

  void onCategorySelected(Category? category) {
    setState(() {
      _selectedCategory = category;
      _fetchTransactions();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();

    _accountEventListener = globalEvent.on("account_update", (data) {
      debugPrint("accounts are changed");
      _fetchTransactions();
    });

    _categoryEventListener = globalEvent.on("category_update", (data) {
      debugPrint("categories are changed");
      _fetchTransactions();
    });

    _paymentEventListener = globalEvent.on("payment_update", (data) {
      debugPrint("payments are changed");
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _accountEventListener?.cancel();
    _categoryEventListener?.cancel();
    _paymentEventListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.menu),
      //     onPressed: (){
      //       Scaffold.of(context).openDrawer();
      //     },
      //   ),
      //   title: const Text("Home", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),),
      // ),
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin:
                const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hi! Good ${greeting()}"),
                BlocConsumer<AppCubit, AppState>(
                    listener: (context, state) {},
                    builder: (context, state) => Text(
                          state.username ?? "Guest",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ))
              ],
            ),
          ),
          AccountsSlider(
            accounts: _accounts,
            onAccountSelected: onAccountSelected,
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              const Text("Payments",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              const Expanded(child: SizedBox()),
              MaterialButton(
                onPressed: () {
                  handleChooseDateRange();
                },
                height: double.minPositive,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                child: Row(
                  children: [
                    Text(
                      "${DateFormat("dd MMM").format(_range.start)} - ${DateFormat("dd MMM").format(_range.end)}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Icon(Icons.arrow_drop_down_outlined)
                  ],
                ),
              ),
            ]),
          ),

          /*

            Horizontal Date picker is added to select a single date

          */
          //TableEventsExample(),
          EasyInfiniteDateTimeLine(
            firstDate: DateTime(2023),
            focusDate: _focusDate,
            lastDate: DateTime.now(),showTimelineHeader: false,
            onDateChange: (selectedDate) {
              setState(() {
                _focusDate = selectedDate;
                _range = DateTimeRange(start: selectedDate, end: selectedDate);
                _fetchTransactions();
              });
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: InkWell(
                  onTap: () {
                    setState(() {
                      _showingIncomeOnly =
                          !_showingIncomeOnly; // Toggle showing income
                      _showingExpenseOnly = false; // Hide expense only
                      _fetchTransactions();
                    });
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: ThemeColors.success.withOpacity(0.2),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text.rich(TextSpan(children: [
                              //TextSpan(text: TextStyle(color: ThemeColors.success)),
                              TextSpan(
                                  text: "Income",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ])),
                            const SizedBox(
                              height: 5,
                            ),
                            CurrencyText(
                              _income,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeColors.success),
                            )
                          ],
                        ),
                      )),
                )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: InkWell(
                  onTap: () {
                    setState(() {
                      _showingExpenseOnly =
                          !_showingExpenseOnly; // Toggle showing expense
                      _showingIncomeOnly = false; // Hide income only
                      _fetchTransactions();
                    });
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: ThemeColors.error.withOpacity(0.2),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text.rich(TextSpan(children: [
                              //TextSpan(text: "▲", style: TextStyle(color: ThemeColors.error)),
                              TextSpan(
                                  text: "Expense",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ])),
                            const SizedBox(
                              height: 5,
                            ),
                            CurrencyText(
                              _expense,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeColors.error),
                            )
                          ],
                        ),
                      )),
                )),
              ],
            ),
          ),
          ExpensePieChart(
            onCategorySelected: onCategorySelected,
          ),
          ExpenseLineChart(
            monthlyExpenses: _monthlyExpenses,
          ),
          _payments.isNotEmpty
              ? ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, index) {
                    return PaymentListItem(
                        payment: _payments[index],
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (builder) => PaymentForm(
                                    type: _payments[index].type,
                                    payment: _payments[index],
                                  )));
                        });
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Container(
                      width: double.infinity,
                      color: Colors.grey.withAlpha(25),
                      height: 1,
                      margin: const EdgeInsets.only(left: 75, right: 20),
                    );
                  },
                  itemCount: _payments.length,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  alignment: Alignment.center,
                  child: const Text("No payments!"),
                ),
        ],
      )),
      /**
           * Buttons to add income and expense
           */
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 16.0),
          FloatingActionButton(
            heroTag: "income",
            onPressed: () => openAddPaymentPage(PaymentType.credit),
            backgroundColor: ThemeColors.success,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10.0),
          FloatingActionButton(
            heroTag: "expense",
            onPressed: () => openAddPaymentPage(PaymentType.debit),
            backgroundColor: ThemeColors.error,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
