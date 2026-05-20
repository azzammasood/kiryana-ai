import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  static final Map<int, Map<String, dynamic>> _latestInsightCache = {};

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  Dio get client => _dio;

  static Map<String, dynamic>? peekInsightCache(int userId) {
    return _latestInsightCache[userId];
  }

  Future<Map<String, dynamic>?> loadPersistedInsight(int userId) async {
    final memory = _latestInsightCache[userId];
    if (memory != null) return memory;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('insight_cache_$userId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _latestInsightCache[userId] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> persistInsightCache(int userId, Map<String, dynamic> insight) async {
    _latestInsightCache[userId] = insight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('insight_cache_$userId', jsonEncode(insight));
  }

  String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'].toString();
        if (_isQuotaError(detail)) {
          return _quotaFriendlyMessage();
        }
        return detail;
      }
      if (error.response?.statusCode == 429 || _isQuotaError(error.message)) {
        return _quotaFriendlyMessage();
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Backend se connection nahi ho raha. FastAPI server check karein.';
      }
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request zyada der tak chal rahi thi. Dobara try karein ya TEST_MODE=true use karein.';
      }
      return error.message ?? 'API request fail ho gayi';
    }
    final text = error.toString();
    if (_isQuotaError(text)) return _quotaFriendlyMessage();
    return text;
  }

  bool _isQuotaError(String? text) {
    if (text == null || text.isEmpty) return false;
    final lower = text.toLowerCase();
    return lower.contains('gemini api ki free limit') ||
        lower.contains('generativelanguage.googleapis.com') ||
        (lower.contains('quota') && lower.contains('exceeded')) ||
        lower.contains('resource_exhausted') ||
        (lower.contains('rate') && lower.contains('limit'));
  }

  String _quotaFriendlyMessage() {
    return 'Gemini API limit hit ho gayi. Backend restart karein after .env key change, '
        'ya TEST_MODE=true set karein.';
  }

  Future<Map<String, dynamic>> createUser(String phoneNumber,
      {String name = 'Dukandaar'}) async {
    final response = await _dio.post(ApiEndpoints.users, data: {
      'phone_number': phoneNumber,
      'name': name,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<int> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt('user_id');
    if (existing != null) return existing;
    final phone = prefs.getString('phone_number');
    if (phone == null || phone.isEmpty) {
      throw Exception('Please login again');
    }
    final user = await createUser(phone, name: 'Kiryana Owner');
    final id = user['id'] as int;
    await prefs.setInt('user_id', id);
    await prefs.setString('phone_number', phone);
    return id;
  }

  Future<void> setCurrentUser(int userId, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('phone_number', phoneNumber);
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_id');
    await prefs.remove('phone_number');
    await prefs.remove('pending_user_id');
    await prefs.remove('pending_phone_number');
  }

  Future<List<dynamic>> getTransactions(int userId,
      {String filter = 'month'}) async {
    final response = await _dio.get(
      ApiEndpoints.transactionsForUser(userId),
      queryParameters: {'filter': filter},
    );
    return response.data as List<dynamic>;
  }

  void clearInsightCache(int userId) {
    _latestInsightCache.remove(userId);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('insight_cache_$userId');
    });
  }

  Future<Map<String, dynamic>> saveTransaction(
      Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.transactions, data: data);
    final userId = data['user_id'];
    if (userId is int) {
      clearInsightCache(userId);
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Regenerate weekly insight after a new log so banners/KPIs stay in sync.
  Future<Map<String, dynamic>?> refreshInsightsAfterTransaction(int userId) async {
    clearInsightCache(userId);
    try {
      var insight = await generateInsights(userId);
      try {
        final kpis = await getAdaptationKpis(userId);
        insight = {...insight, 'kpis': kpis};
      } catch (_) {}
      await persistInsightCache(userId, insight);
      return insight;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete(ApiEndpoints.transactionById(id));
  }

  Future<Map<String, dynamic>> processVoiceBytes({
    required Uint8List bytes,
    required String fileName,
    required int userId,
  }) async {
    final form = FormData.fromMap({
      'user_id': userId,
      'audio_file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('audio', 'webm'),
      ),
    });
    final response = await _dio.post(
      ApiEndpoints.processVoice,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> generateInsights(int userId) async {
    final response = await _dio.post(ApiEndpoints.generateInsights(userId));
    final insight = Map<String, dynamic>.from(response.data as Map);
    await persistInsightCache(userId, insight);
    return insight;
  }

  Future<Map<String, dynamic>> getLatestInsight(int userId) async {
    final cached = _latestInsightCache[userId];
    if (cached != null) return cached;
    final response = await _dio.get(ApiEndpoints.latestInsight(userId));
    final insight = Map<String, dynamic>.from(response.data as Map);
    await persistInsightCache(userId, insight);
    return insight;
  }

  Future<List<dynamic>> getAgentTrace(int userId) async {
    final response = await _dio.get(ApiEndpoints.agentTrace(userId));
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getInsightSessions(int userId) async {
    final response = await _dio.get(ApiEndpoints.insightSessions(userId));
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getAgentTraceBySession(int userId, String sessionId) async {
    final response = await _dio.get(ApiEndpoints.traceBySession(userId, sessionId));
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitVoiceFeedback({
    required int userId,
    required bool isCorrect,
    int? sourceTransactionId,
    String? sessionId,
    String? rawTranscript,
    Map<String, dynamic>? parsedPayload,
    Map<String, dynamic>? correctedPayload,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.voiceFeedback,
      data: {
        'user_id': userId,
        'source_transaction_id': sourceTransactionId,
        'session_id': sessionId,
        'raw_transcript': rawTranscript,
        'parsed_payload': parsedPayload,
        'corrected_payload': correctedPayload,
        'is_correct': isCorrect,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> submitRecommendationFeedback({
    required int userId,
    required int insightId,
    required String recommendationText,
    required bool accepted,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.recommendationFeedback,
      data: {
        'user_id': userId,
        'insight_id': insightId,
        'recommendation_text': recommendationText,
        'accepted': accepted,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdaptationKpis(int userId) async {
    final response = await _dio.get(ApiEndpoints.adaptationKpis(userId));
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> askInsightQuestion({
    required int userId,
    required String question,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.askInsight(userId),
      data: {'question': question},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> transcribeVoiceBytes({
    required Uint8List bytes,
    required String fileName,
    required int userId,
  }) async {
    final form = FormData.fromMap({
      'user_id': userId,
      'audio_file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('audio', 'webm'),
      ),
    });
    final response = await _dio.post(
      ApiEndpoints.transcribe,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> refineLearning(int userId) async {
    await _dio.post(ApiEndpoints.refineLearning(userId));
  }

  Future<void> clearLearning(int userId) async {
    await _dio.post(ApiEndpoints.clearLearning(userId));
  }

  Future<Map<String, dynamic>> getLatestInsightWithKpis(int userId) async {
    final cached = _latestInsightCache[userId] ??
        await loadPersistedInsight(userId);
    if (cached != null && cached['kpis'] != null) {
      return cached;
    }

    Map<String, dynamic> insight;
    try {
      insight = await getLatestInsight(userId);
    } catch (_) {
      insight = await generateInsights(userId);
    }
    try {
      final kpis = await getAdaptationKpis(userId);
      insight = {...insight, 'kpis': kpis};
    } catch (_) {
      insight = {...insight, 'kpis': insight['kpis'] ?? {}};
    }
    await persistInsightCache(userId, insight);
    return insight;
  }

  Future<Map<String, dynamic>> askVoiceInsightQuestion({
    required Uint8List bytes,
    required String fileName,
    required int userId,
    String? questionHint,
  }) async {
    final form = FormData.fromMap({
      'user_id': userId,
      if (questionHint != null && questionHint.trim().isNotEmpty)
        'question_hint': questionHint.trim(),
      'audio_file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('audio', 'webm'),
      ),
    });
    final response = await _dio.post(
      ApiEndpoints.askVoice,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> sendWhatsApp(int userId) async {
    final response = await _dio.post(ApiEndpoints.sendWhatsApp(userId));
    return Map<String, dynamic>.from(response.data as Map);
  }
}
