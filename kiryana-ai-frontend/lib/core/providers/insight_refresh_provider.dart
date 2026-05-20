import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to notify insight banners/screens to reload from backend.
final insightRefreshProvider = StateProvider<int>((ref) => 0);

void bumpInsightRefresh(WidgetRef ref) {
  ref.read(insightRefreshProvider.notifier).state++;
}
