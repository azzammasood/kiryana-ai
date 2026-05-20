/// OnboardingPageModel — represents one onboarding slide.
/// UI should only ever consume this model, not raw strings.
class OnboardingPageModel {
  final int index;
  final String titleUrdu;     // Urdu heading
  final String subtitleEn;    // English subtitle
  final String imagePath; // Path to the asset image

  const OnboardingPageModel({
    required this.index,
    required this.titleUrdu,
    required this.subtitleEn,
    required this.imagePath,
  });
}
