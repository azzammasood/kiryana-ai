import '../models/transaction_model.dart';

class LogItem {
  final String id;
  final String titleUrdu;
  final String titleEnglish;
  final String tag;
  final String time;
  final int amount;
  final bool isSale;
  final String iconType;

  const LogItem({
    required this.id,
    required this.titleUrdu,
    required this.titleEnglish,
    required this.tag,
    required this.time,
    required this.amount,
    required this.isSale,
    required this.iconType,
  });
}

class LogGroup {
  final String date;
  final List<TransactionModel> items;

  const LogGroup({
    required this.date,
    required this.items,
  });
}

class MockLogsData {
  // These are kept as LogItem for initial seeding only
  static const List<LogItem> dailyLogItems = [
    LogItem(
      id: '1',
      titleUrdu: 'چینی',
      titleEnglish: 'Sugar',
      tag: '5kg',
      time: '10:30 AM',
      amount: 600,
      isSale: true,
      iconType: 'sugar',
    ),
    LogItem(
      id: '2',
      titleUrdu: 'کرایہ',
      titleEnglish: 'Transport',
      tag: '-',
      time: '11:15 AM',
      amount: 350,
      isSale: false,
      iconType: 'transport',
    ),
    LogItem(
      id: '3',
      titleUrdu: 'انڈے',
      titleEnglish: 'Eggs',
      tag: '2 Dozen',
      time: '12:45 PM',
      amount: 560,
      isSale: true,
      iconType: 'eggs',
    ),
    LogItem(
      id: '4',
      titleUrdu: 'آٹا',
      titleEnglish: 'Flour',
      tag: '10kg',
      time: '02:10 PM',
      amount: 1200,
      isSale: true,
      iconType: 'flour',
    ),
    LogItem(
      id: '5',
      titleUrdu: 'چاول',
      titleEnglish: 'Rice',
      tag: '2kg',
      time: '06:00 PM',
      amount: 500,
      isSale: true,
      iconType: 'rice',
    ),
  ];

  static const List<LogItem> weeklyLogItems = [
    LogItem(
      id: 'w1',
      titleUrdu: 'ہول سیل ادائیگی',
      titleEnglish: 'Wholesale Payment',
      tag: 'Supplier',
      time: '10:00 AM',
      amount: 15000,
      isSale: false,
      iconType: 'receipt',
    ),
    LogItem(
      id: 'w2',
      titleUrdu: 'بسکٹ کارٹن',
      titleEnglish: 'Biscuits Carton',
      tag: '2 Boxes',
      time: '04:30 PM',
      amount: 2400,
      isSale: true,
      iconType: 'receipt',
    ),
  ];
}
