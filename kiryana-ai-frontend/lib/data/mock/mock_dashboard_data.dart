class DashboardMockData {
  static const double todaysSales = 45200;
  static const double todaysExpenses = 12500;

  // Represents 7 days of the week (Mon to Sun)
  // Positive values are sales, negative are expenses.
  // 0 means no data/empty.
  static const List<double> weeklyData = [
    20000,   // Mon: Sales
    35000,   // Tue: Sales
    15000,   // Wed: Sales
    -25000,  // Thu: Expenses (Red)
    40000,   // Fri: Sales
    18000,   // Sat: Sales
    0,       // Sun: No data
  ];

  static const String currentInsightUrdu = 'آٹے کی فروخت کم ہو رہی ہے — اسٹاک کم کرو';
  static const String currentInsightEnglish = 'Atta sales are decreasing — reduce stock';
}
