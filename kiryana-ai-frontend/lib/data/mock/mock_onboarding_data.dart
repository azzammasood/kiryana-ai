import '../models/onboarding_model.dart';

/// MockOnboardingDataSource
/// All onboarding content lives here — NOT inside widgets.
/// When backend provides this data, replace this class with ApiOnboardingDataSource.
class MockOnboardingDataSource {
  static List<OnboardingPageModel> getPages() {
    return const [
      OnboardingPageModel(
        index: 1,
        titleUrdu: 'بول کے لکھو',
        subtitleEn: 'Speak to log sales & expenses',
        imagePath: 'assets/images/oboarding1.png',
      ),
      OnboardingPageModel(
        index: 2,
        titleUrdu: 'بر حفتے کا حساب',
        subtitleEn: 'Weekly Summary',
        imagePath: 'assets/images/onboarding2.png',
      ),
      OnboardingPageModel(
        index: 3,
        titleUrdu: 'فائدہ اور نکسان',
        subtitleEn: 'Profit and Loss',
        imagePath: 'assets/images/onboarding3.png',
      ),
    ];
  }
}
