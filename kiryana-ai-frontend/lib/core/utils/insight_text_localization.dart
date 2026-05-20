final _arabicScript = RegExp(r'[\u0600-\u06FF]');

/// Localize Roman Urdu key insights for Urdu-script UI.
String localizedKeyInsight(String raw, bool isUrdu) {
  final text = raw.trim();
  if (!isUrdu || text.isEmpty) return text;
  if (_arabicScript.hasMatch(text)) return text;

  final salesMatch =
      RegExp(r'bikri\s+Rs\.?\s*([0-9.,]+)', caseSensitive: false).firstMatch(text);
  final expenseMatch =
      RegExp(r'kharcha\s+Rs\.?\s*([0-9.,]+)', caseSensitive: false).firstMatch(text);
  if (salesMatch != null && expenseMatch != null) {
    return 'اس ہفتے فروخت Rs. ${salesMatch.group(1)} اور خرچ Rs. ${expenseMatch.group(1)} ریکارڈ ہوا۔';
  }

  if (text.toLowerCase().contains('bikri zero') ||
      text.toLowerCase().contains('zero hai')) {
    final exp = expenseMatch?.group(1) ?? '0';
    return 'اس ہفتے فروخت صفر ہے، مگر Rs. $exp خرچ ریکارڈ ہوا۔ پہلی فروخت لگائیں۔';
  }

  if (text.contains('ab tak sab se zyada bikne wali cheez')) {
    final itemMatch = RegExp(r'^(.+?)\s+ab tak', caseSensitive: false).firstMatch(text);
    final amountMatch = RegExp(r'Rs\.?\s*([0-9.,]+)').firstMatch(text);
    final item = itemMatch?.group(1)?.trim() ?? 'یہ آئٹم';
    final amount = amountMatch?.group(1) ?? '0';
    return '$item اب تک سب سے زیادہ بکنے والی چیز ہے (Rs. $amount)۔ اس کا اسٹاک زیادہ رکھیں۔';
  }

  if (text.contains('Pehle din se aakhri din tak bikri barh rahi')) {
    return 'پہلے دن سے آخری دن تک فروخت بڑھ رہی ہے۔ اس رجحان کو برقرار رکھیں۔';
  }

  if (text.contains('Bikri pehle din se kam ho rahi')) {
    return 'فروخت پہلے دن سے کم ہو رہی ہے۔ کاؤنٹر ڈسپلے اور ریٹ بورڈ چیک کریں۔';
  }

  if (text.contains('Abhi kam entries hain')) {
    return 'ابھی کم انٹریز ہیں — روزانہ آواز سے فروخت/خرچ لاگ کریں تاکہ رجحان واضح ہو۔';
  }

  if (text.contains('Rozana 2–3 voice entries') ||
      text.contains('rozana voice')) {
    return 'روزانہ 2–3 وائس انٹریز سے ایک ہفتے میں مضبوط رجحان بنے گا۔';
  }

  return text;
}
