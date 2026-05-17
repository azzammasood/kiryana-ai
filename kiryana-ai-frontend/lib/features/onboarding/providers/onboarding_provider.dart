import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/onboarding_model.dart';
import '../../../data/repositories/onboarding_repository.dart';

/// Provider for the onboarding repository.
/// To switch to API: change MockOnboardingRepository() to ApiOnboardingRepository()
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return const MockOnboardingRepository();
});

/// Provider that exposes the list of onboarding pages to the UI.
final onboardingPagesProvider = Provider<List<OnboardingPageModel>>((ref) {
  return ref.watch(onboardingRepositoryProvider).getOnboardingPages();
});

/// Onboarding page index state notifier
class OnboardingNotifier extends StateNotifier<int> {
  OnboardingNotifier() : super(0);

  void nextPage(int totalPages) {
    if (state < totalPages - 1) {
      state = state + 1;
    }
  }

  void previousPage() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void goToPage(int index) {
    state = index;
  }

  bool get isLastPage => state == 2; // Will be updated dynamically
}

final onboardingPageIndexProvider =
    StateNotifierProvider<OnboardingNotifier, int>((ref) {
  return OnboardingNotifier();
});
