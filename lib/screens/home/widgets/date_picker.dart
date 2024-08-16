import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalender extends StatefulWidget {
  final Function(DateTimeRange) updateDateRange;
  const CustomCalender({super.key, required this.updateDateRange});

  @override
  State<CustomCalender> createState() => _CustomCalenderState();
}

class _CustomCalenderState extends State<CustomCalender> {
  final PaymentDao _paymentDao = PaymentDao();

  late final ValueNotifier<List<Payment>> _selectedPayments;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Cache for payments to use with eventLoader
  final Map<DateTime, List<Payment>> _paymentCache = {};

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedPayments = ValueNotifier([]);
    _fetchPaymentsForDay(_selectedDay!);
  }

  @override
  void dispose() {
    _selectedPayments.dispose();
    super.dispose();
  }

  Future<void> _fetchPaymentsForDay(DateTime day) async {
    final payments = await _paymentDao.find(
      range: DateTimeRange(start: day, end: day),
    );
    setState(() {
      _paymentCache[day] = payments;
      _selectedPayments.value = payments;
    });
  }

  Future<void> _fetchPaymentsForRange(DateTime start, DateTime end) async {
    final payments = await _paymentDao.find(
      range: DateTimeRange(start: start, end: end),
    );
    setState(() {
      // Cache the payments for each day in the range
      for (final payment in payments) {
        final day = DateTime(payment.datetime.year, payment.datetime.month,
            payment.datetime.day);
        if (_paymentCache[day] == null) {
          _paymentCache[day] = [];
        }
        _paymentCache[day]!.add(payment);
      }
      _selectedPayments.value = payments;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _fetchPaymentsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _fetchPaymentsForRange(start, end);
      widget.updateDateRange(DateTimeRange(start: start, end: end));
    } else if (start != null) {
      _fetchPaymentsForDay(start);
    } else if (end != null) {
      _fetchPaymentsForDay(end);
    }
  }

  List<Payment> _getPaymentsForDay(DateTime day) {
    return _paymentCache[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
      ),
      body: Column(
        children: [
          TableCalendar<Payment>(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getPaymentsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 0,
                    right: 2.0, // Adjust the right offset as needed
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(
                          6.0), // Adjust padding for increased size
                      child: Center(
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0, // Adjust font size as needed
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Payment>>(
              valueListenable: _selectedPayments,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text(value[index].title),
                        subtitle: Text('Amount: ${value[index].amount}'),
                        trailing: Text(value[index].type.name),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Define constants for the calendar
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
