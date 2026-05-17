import '../../data/models/onboarding_model.dart';
import '../../data/mock/mock_onboarding_data.dart';

/// Abstract repository interface.
/// UI and providers depend on this — NOT on the mock or API implementation.
/// To connect backend: create ApiOnboardingRepository implements OnboardingRepository.
abstract class OnboardingRepository {
  List<OnboardingPageModel> getOnboardingPages();
}

/// Mock implementation — used until API is ready.
class MockOnboardingRepository implements OnboardingRepository {
  const MockOnboardingRepository();

  @override
  List<OnboardingPageModel> getOnboardingPages() {
    return MockOnboardingDataSource.getPages();
  }
}
