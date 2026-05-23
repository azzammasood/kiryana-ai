import 'package:flutter_test/flutter_test.dart';
import 'package:kiryana_ai/core/utils/recommendation_localization.dart';

void main() {
  test('shows stock recommendation in both selected languages', () {
    final recommendation = LocalizedRecommendation.fromDynamic(
      'اس چیز کا اسٹاک ہمیشہ موجود رکھیں تاکہ فروخت مس نہ ہو',
    );

    expect(
      recommendation.displayText(false),
      'Keep this item in stock so you do not miss sales.',
    );
    expect(
      recommendation.displayText(true),
      'اس چیز کا اسٹاک ہمیشہ موجود رکھیں تاکہ فروخت مس نہ ہو',
    );
  });

  test('shows Roman Urdu top-seller recommendation in both languages', () {
    final recommendation = LocalizedRecommendation.fromDynamic(
      'atta ab tak sab se zyada bikne wali cheez hai (Rs. 2800). '
      'Is item ka stock zyada rakhein.',
    );

    expect(
      recommendation.displayText(false),
      'Atta is your top-selling item so far (Rs. 2800). '
      'Keep extra stock for it.',
    );
    expect(
      recommendation.displayText(true),
      'آٹا اب تک سب سے زیادہ بکنے والی چیز ہے (Rs. 2800)۔ '
      'اس کا اسٹاک زیادہ رکھیں۔',
    );
  });
}
