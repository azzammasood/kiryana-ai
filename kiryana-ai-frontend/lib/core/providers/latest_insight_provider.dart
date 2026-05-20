import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'insight_refresh_provider.dart';

class LatestInsightState {
  final Map<String, dynamic>? data;
  final bool isRefreshing;
  final String? error;

  const LatestInsightState({
    this.data,
    this.isRefreshing = false,
    this.error,
  });

  bool get showFullScreenLoader => isRefreshing && data == null;

  LatestInsightState copyWith({
    Map<String, dynamic>? data,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return LatestInsightState(
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LatestInsightNotifier extends StateNotifier<LatestInsightState> {
  LatestInsightNotifier(this._ref) : super(const LatestInsightState()) {
    _bootstrap();
    _ref.listen<int>(insightRefreshProvider, (previous, next) {
      if (previous != next) {
        reload(force: true);
      }
    });
  }

  final Ref _ref;
  bool _loadedOnce = false;

  Future<void> _bootstrap() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    try {
      final userId = await ApiService().currentUserId();
      final cached = ApiService.peekInsightCache(userId) ??
          await ApiService().loadPersistedInsight(userId);
      if (cached != null) {
        state = LatestInsightState(data: cached);
        return;
      }
    } catch (_) {
      // Fall through to network load.
    }
    await reload();
  }

  Future<void> reload({bool force = false}) async {
    if (!force) {
      if (state.data != null) return;
      try {
        final userId = await ApiService().currentUserId();
        final cached = ApiService.peekInsightCache(userId) ??
            await ApiService().loadPersistedInsight(userId);
        if (cached != null) {
          state = LatestInsightState(data: cached);
          return;
        }
      } catch (_) {}
    }

    final hadData = state.data != null;
    state = state.copyWith(
      isRefreshing: !hadData,
      clearError: true,
    );

    try {
      final api = ApiService();
      final userId = await api.currentUserId();
      Map<String, dynamic> insight;
      if (force) {
        insight = await api.generateInsights(userId);
        try {
          final kpis = await api.getAdaptationKpis(userId);
          insight = {...insight, 'kpis': kpis};
        } catch (_) {}
      } else {
        insight = await api.getLatestInsightWithKpis(userId);
      }
      await api.persistInsightCache(userId, insight);
      state = LatestInsightState(data: insight);
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        error: ApiService().errorMessage(error),
      );
    }
  }

  void mergePatch(Map<String, dynamic> patch) {
    final current = state.data;
    if (current == null) return;
    state = LatestInsightState(data: {...current, ...patch});
  }
}

final latestInsightProvider =
    StateNotifierProvider<LatestInsightNotifier, LatestInsightState>((ref) {
  return LatestInsightNotifier(ref);
});
