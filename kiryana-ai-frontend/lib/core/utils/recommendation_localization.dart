final _arabicScript = RegExp(r'[\u0600-\u06FF]');

bool _looksEnglish(String text) {
  final letters = text.split('').where((ch) => RegExp(r'[A-Za-z]').hasMatch(ch));
  if (letters.isEmpty) return false;
  final latin = letters.where((ch) => ch.codeUnitAt(0) < 128).length;
  return latin / letters.length >= 0.85 && !_arabicScript.hasMatch(text);
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
    if (isUrdu) {
      final ur = textUrdu.trim();
      final en = textEnglish.trim();
      if (ur.isNotEmpty && _arabicScript.hasMatch(ur)) return ur;
      if (en.isNotEmpty && _arabicScript.hasMatch(en)) return en;
      if (ur.isNotEmpty && !_looksEnglish(ur)) return ur;
      if (en.isNotEmpty && !_looksEnglish(en)) return en;
      return '';
    }
    if (textEnglish.trim().isNotEmpty) {
      return textEnglish.trim();
    }
    final ur = textUrdu.trim();
    if (ur.isEmpty) return '';
    if (_arabicScript.hasMatch(ur)) return ur;
    if (!_looksEnglish(ur)) return ur;
    return '';
  }

  static LocalizedRecommendation fromDynamic(dynamic item) {
    if (item is Map) {
      final en = (item['en'] ??
              item['action_en'] ??
              item['action'] ??
              item['text_en'] ??
              '')
          .toString()
          .trim();
      final ur = (item['ur'] ??
              item['action_urdu'] ??
              item['text_ur'] ??
              '')
          .toString()
          .trim();
      return LocalizedRecommendation(textEnglish: en, textUrdu: ur);
    }
    final text = item.toString().trim();
    final hasArabic = _arabicScript.hasMatch(text);
    if (hasArabic) {
      return LocalizedRecommendation(textEnglish: '', textUrdu: text);
    }
    return LocalizedRecommendation(textEnglish: text, textUrdu: text);
  }
}
