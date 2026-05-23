final _arabicScript = RegExp(r'[\u0600-\u06FF]');
final _amountPattern = RegExp(r'Rs\.?\s*([0-9.,]+)', caseSensitive: false);

String _cleanText(String text) {
  return text.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _titleCaseItem(String item) {
  final cleaned = _cleanText(item);
  if (cleaned.isEmpty) return 'This item';
  return cleaned.split(' ').map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}

String _romanListToEnglish(String text) {
  return _cleanText(text)
      .replaceAll(RegExp(r'\baur\b', caseSensitive: false), 'and')
      .replaceAll(RegExp(r'\s+and\s+'), ' and ');
}

String _itemToUrdu(String rawItem) {
  final item = _cleanText(rawItem);
  final lower = item.toLowerCase();
  const replacements = {
    'atta': 'آٹا',
    'flour': 'آٹا',
    'doodh': 'دودھ',
    'milk': 'دودھ',
    'cheeni': 'چینی',
    'sugar': 'چینی',
    'sabzi': 'سبزی',
    'vegetables': 'سبزی',
    'anday': 'انڈے',
    'ande': 'انڈے',
    'eggs': 'انڈے',
    'transport': 'ٹرانسپورٹ',
    'mazdoori': 'مزدوری',
  };
  return replacements[lower] ?? item;
}

String _itemListToUrdu(String rawList) {
  final parts = rawList
      .split(RegExp(r',|\baur\b|\band\b', caseSensitive: false))
      .map(_cleanText)
      .where((part) => part.isNotEmpty)
      .map(_itemToUrdu)
      .toList();

  if (parts.isEmpty) return _cleanText(rawList);
  if (parts.length == 1) return parts.first;
  return '${parts.take(parts.length - 1).join('، ')}، اور ${parts.last}';
}

String? _englishFromKnownText(String text) {
  final cleaned = _cleanText(text);
  if (cleaned.isEmpty) return null;
  final lower = cleaned.toLowerCase();

  if (_arabicScript.hasMatch(cleaned)) {
    if (cleaned.contains('اس چیز') &&
        cleaned.contains('اسٹاک') &&
        cleaned.contains('فروخت')) {
      return 'Keep this item in stock so you do not miss sales.';
    }
    return 'Review this week\'s sales and stock based on your latest logs.';
  }

  if (lower.contains('is cheez ka stock') ||
      lower.contains('stock hamesha موجود') ||
      (lower.contains('stock') &&
          lower.contains('hamesha') &&
          lower.contains('farokht'))) {
    return 'Keep this item in stock so you do not miss sales.';
  }

  if (lower.contains('ab tak sab se zyada bikne wali cheez')) {
    final item = _titleCaseItem(
      cleaned.split(RegExp('ab tak', caseSensitive: false)).first,
    );
    final amount = _amountPattern.firstMatch(cleaned)?.group(1);
    final amountText = amount == null ? '' : ' (Rs. $amount)';
    return '$item is your top-selling item so far$amountText. Keep extra stock for it.';
  }

  if (lower.contains('aapke sab se zyada bikne wale items') ||
      lower.contains('sab se zyada bikne wale items')) {
    final itemList = _romanListToEnglish(
      cleaned
          .split(RegExp('aapke', caseSensitive: false))
          .first
          .replaceAll(RegExp(r'\s+$'), ''),
    );
    final subject = itemList.isEmpty ? 'Your top items' : itemList;
    return '$subject are your top-selling items. Keep their stock available and maintain quality so customers do not face shortages.';
  }

  if (lower.contains('transport ke akhrajaat') ||
      lower.contains('transport ka kharcha')) {
    return 'Keep an eye on transport expenses. They are a large share of your total expenses. Buy more stock in one trip or use a nearby wholesale market to reduce repeated travel.';
  }

  if (lower.contains('top selling items ka stock daily check')) {
    return 'Check top-selling item stock daily.';
  }

  if (lower.contains('expenses ko daily record')) {
    return 'Record expenses daily so profit stays clear.';
  }

  if (lower.contains('high demand items') && lower.contains('reorder point')) {
    return 'Set a reorder point for high-demand items.';
  }

  if (lower.contains('pehle din se aakhri din tak bikri barh rahi')) {
    final amount = _amountPattern.firstMatch(cleaned)?.group(1);
    final suffix = amount == null ? '' : ' (about Rs. $amount)';
    return 'Sales are rising from the first day to the last$suffix. Keep this momentum.';
  }

  if (lower.contains('bikri pehle din se kam ho rahi')) {
    final amount = _amountPattern.firstMatch(cleaned)?.group(1);
    final suffix = amount == null ? '' : ' (about Rs. $amount)';
    return 'Sales are falling from the first day to the last$suffix. Review pricing and display.';
  }

  if (lower.contains('do din ki bikri barabar')) {
    return 'Sales are steady across the first days. Keep top items stocked.';
  }

  if (lower.contains('abhi kam entries')) {
    return 'Few entries so far. Log sales and expenses daily with voice so the trend is clear.';
  }

  if (lower.contains('rozana') && lower.contains('voice')) {
    return 'Log 2-3 voice entries daily to build a strong weekly trend.';
  }

  return null;
}

String? _urduFromKnownText(String text) {
  final cleaned = _cleanText(text);
  if (cleaned.isEmpty) return null;
  if (_arabicScript.hasMatch(cleaned)) return cleaned;

  final lower = cleaned.toLowerCase();

  if (lower.contains('is cheez ka stock') ||
      lower.contains('keep this item in stock') ||
      (lower.contains('stock') &&
          lower.contains('hamesha') &&
          lower.contains('farokht'))) {
    return 'اس چیز کا اسٹاک ہمیشہ موجود رکھیں تاکہ فروخت مس نہ ہو۔';
  }

  if (lower.contains('ab tak sab se zyada bikne wali cheez') ||
      lower.contains('top-selling item so far')) {
    final itemSource = lower.contains('ab tak')
        ? cleaned.split(RegExp('ab tak', caseSensitive: false)).first
        : cleaned.split(RegExp('is your', caseSensitive: false)).first;
    final item = _itemToUrdu(itemSource);
    final amount = _amountPattern.firstMatch(cleaned)?.group(1);
    final amountText = amount == null ? '' : ' (Rs. $amount)';
    return '$item اب تک سب سے زیادہ بکنے والی چیز ہے$amountText۔ اس کا اسٹاک زیادہ رکھیں۔';
  }

  if (lower.contains('aapke sab se zyada bikne wale items') ||
      lower.contains('sab se zyada bikne wale items') ||
      lower.contains('top-selling items')) {
    final source = lower.contains('aapke')
        ? cleaned.split(RegExp('aapke', caseSensitive: false)).first
        : cleaned.split(RegExp('are your', caseSensitive: false)).first;
    final items = _itemListToUrdu(source);
    return '$items آپ کی سب سے زیادہ بکنے والی چیزیں ہیں۔ ان کا اسٹاک ہمیشہ موجود رکھیں اور معیار پر سمجھوتہ نہ کریں۔';
  }

  if (lower.contains('transport ke akhrajaat') ||
      lower.contains('transport expenses') ||
      lower.contains('transport ka kharcha')) {
    return 'ٹرانسپورٹ کے اخراجات پر نظر رکھیں۔ یہ کل خرچ کا بڑا حصہ ہیں۔ ایک ہی بار میں زیادہ مال اٹھائیں یا قریبی ہول سیل مارکیٹ سے خریداری کریں تاکہ بار بار سفر کم ہو۔';
  }

  if (lower.contains('top selling items ka stock daily check') ||
      lower.contains('check top-selling item stock daily')) {
    return 'ٹاپ سیلنگ آئٹمز کا اسٹاک روزانہ چیک کریں۔';
  }

  if (lower.contains('expenses ko daily record') ||
      lower.contains('record expenses daily')) {
    return 'خرچ روزانہ ریکارڈ کریں تاکہ منافع واضح رہے۔';
  }

  if (lower.contains('high demand items') && lower.contains('reorder point')) {
    return 'زیادہ مانگ والی چیزوں کے لیے ری آرڈر پوائنٹ مقرر کریں۔';
  }

  if (lower.contains('pehle din se aakhri din tak bikri barh rahi') ||
      lower.contains('sales are rising')) {
    return 'پہلے دن سے آخری دن تک فروخت بڑھ رہی ہے۔ اس رجحان کو برقرار رکھیں۔';
  }

  if (lower.contains('bikri pehle din se kam ho rahi') ||
      lower.contains('sales are falling')) {
    return 'فروخت پہلے دن سے کم ہو رہی ہے۔ کاؤنٹر ڈسپلے اور ریٹ بورڈ چیک کریں۔';
  }

  if (lower.contains('do din ki bikri barabar') ||
      lower.contains('sales are steady')) {
    return 'دو دن کی فروخت برابر ہے۔ ٹاپ آئٹمز کا اسٹاک تیار رکھیں۔';
  }

  if (lower.contains('abhi kam entries') || lower.contains('few entries')) {
    return 'ابھی کم انٹریز ہیں۔ روزانہ آواز سے فروخت اور خرچ لاگ کریں تاکہ رجحان واضح ہو۔';
  }

  if (lower.contains('only') &&
      lower.contains('days') &&
      lower.contains('data')) {
    final days = RegExp(r'only\s+(\d+)\s+days?', caseSensitive: false)
        .firstMatch(cleaned)
        ?.group(1);
    final daysText = days ?? 'کم';
    return 'ابھی صرف $daysText دن کا ڈیٹا ہے، اس لیے رجحان محدود ہے۔ روزانہ لاگ جاری رکھیں۔';
  }

  if (lower.contains('rozana') && lower.contains('voice')) {
    return 'روزانہ 2-3 وائس انٹریز سے ایک ہفتے میں مضبوط رجحان بنے گا۔';
  }

  return null;
}

String _normalizeEnglish(String text, String alternate) {
  final cleaned = _cleanText(text);
  final alt = _cleanText(alternate);
  final known = _englishFromKnownText(cleaned);
  if (known != null) return known;

  if (cleaned.isNotEmpty && !_arabicScript.hasMatch(cleaned)) {
    return cleaned;
  }

  final alternateKnown = _englishFromKnownText(alt);
  if (alternateKnown != null) return alternateKnown;
  if (alt.isNotEmpty && !_arabicScript.hasMatch(alt)) return alt;
  return cleaned;
}

String _normalizeUrdu(String text, String alternate) {
  final cleaned = _cleanText(text);
  final alt = _cleanText(alternate);
  final known = _urduFromKnownText(cleaned);
  if (known != null) return known;

  final alternateKnown = _urduFromKnownText(alt);
  if (alternateKnown != null) return alternateKnown;
  return cleaned.isNotEmpty ? cleaned : alt;
}

class LocalizedRecommendation {
  final String textEnglish;
  final String textUrdu;

  const LocalizedRecommendation({
    required this.textEnglish,
    required this.textUrdu,
  });

  /// Stable key for feedback API (prefer English).
  String get feedbackKey =>
      textEnglish.trim().isNotEmpty ? textEnglish.trim() : textUrdu.trim();

  String displayText(bool isUrdu) {
    final preferred = (isUrdu ? textUrdu : textEnglish).trim();
    if (preferred.isNotEmpty) return preferred;
    return (isUrdu ? textEnglish : textUrdu).trim();
  }

  static LocalizedRecommendation fromDynamic(dynamic item) {
    String en = '';
    String ur = '';

    if (item is Map) {
      en = (item['en'] ??
              item['action_en'] ??
              item['action'] ??
              item['text_en'] ??
              '')
          .toString();
      ur = (item['ur'] ?? item['action_urdu'] ?? item['text_ur'] ?? '')
          .toString();
    } else {
      final text = item.toString();
      if (_arabicScript.hasMatch(text)) {
        ur = text;
      } else {
        en = text;
        ur = text;
      }
    }

    final englishSource = en.trim().isNotEmpty ? en : ur;
    final urduSource = ur.trim().isNotEmpty ? ur : en;

    return LocalizedRecommendation(
      textEnglish: _normalizeEnglish(englishSource, urduSource),
      textUrdu: _normalizeUrdu(urduSource, englishSource),
    );
  }
}
