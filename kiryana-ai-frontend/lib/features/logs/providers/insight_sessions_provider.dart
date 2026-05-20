import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/agent_trace_model.dart';

class InsightSessionsState {
  final List<AgentTraceSession> sessions;
  final bool isLoading;
  final String? error;

  const InsightSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  InsightSessionsState copyWith({
    List<AgentTraceSession>? sessions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return InsightSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InsightSessionsNotifier extends StateNotifier<InsightSessionsState> {
  InsightSessionsNotifier() : super(const InsightSessionsState());

  Future<void> load({bool force = false}) async {
    final userId = await ApiService().currentUserId();
    final cached = ApiService.peekInsightSessionsCache(userId);

    if (!force && cached != null && cached.isNotEmpty) {
      state = InsightSessionsState(
        sessions: _mapSessions(cached),
      );
      _refreshInBackground(userId);
      return;
    }

    if (cached != null && cached.isNotEmpty) {
      state = InsightSessionsState(sessions: _mapSessions(cached));
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    await _fetch(userId, force: force);
  }

  Future<void> _refreshInBackground(int userId) async {
    try {
      await _fetch(userId, force: true, silent: true);
    } catch (_) {}
  }

  Future<void> _fetch(
    int userId, {
    required bool force,
    bool silent = false,
  }) async {
    try {
      final rows = await ApiService().getInsightSessions(userId, force: force);
      state = InsightSessionsState(sessions: _mapSessions(rows));
    } catch (error) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: ApiService().errorMessage(error),
        );
      }
    }
  }

  List<AgentTraceSession> _mapSessions(List<dynamic> rows) {
    return rows
        .map(
          (row) => AgentTraceSession.fromApi(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  void invalidate() {
    ApiService.clearInsightSessionsCache();
    state = const InsightSessionsState();
  }
}

final insightSessionsProvider =
    StateNotifierProvider<InsightSessionsNotifier, InsightSessionsState>(
  (ref) => InsightSessionsNotifier(),
);
