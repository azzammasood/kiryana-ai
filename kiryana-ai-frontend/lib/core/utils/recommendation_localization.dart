final _arabicScript = RegExp(r'[\u0600-\u06FF]');

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
      return textUrdu.trim().isNotEmpty ? textUrdu.trim() : textEnglish.trim();
    }
    if (textEnglish.trim().isNotEmpty) {
      return textEnglish.trim();
    }
    final ur = textUrdu.trim();
    if (ur.isEmpty) return '';
    if (_arabicScript.hasMatch(ur)) return '';
    return ur;
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
