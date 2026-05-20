abstract class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String users = '/users/';
  static String user(int userId) => '/users/$userId';

  static const String transcribe = '/voice/transcribe';
  static const String askVoice = '/voice/ask';
  static const String processVoice = '/voice/process';
  static const String parseTransaction = '/voice/parse';

  static const String transactions = '/transactions/';
  static String transactionsForUser(int userId) => '/transactions/$userId';
  static String transactionSummary(int userId) =>
      '/transactions/$userId/summary';
  static String recentTransactions(int userId) =>
      '/transactions/$userId/recent';
  static String transactionById(String id) => '/transactions/$id';

  static String generateInsights(int userId) => '/insights/generate/$userId';
  static String latestInsight(int userId) => '/insights/$userId/latest';
  static String insightSessions(int userId) => '/insights/$userId/sessions';
  static String agentTrace(int userId) => '/insights/$userId/trace';
  static String traceBySession(int userId, String sessionId) =>
      '/insights/$userId/trace/$sessionId';
  static const String voiceFeedback = '/insights/feedback/voice';
  static const String recommendationFeedback = '/insights/feedback/recommendation';
  static String adaptationKpis(int userId) => '/insights/$userId/kpis';
  static String askInsight(int userId) => '/insights/$userId/ask';
  static String refineLearning(int userId) => '/insights/$userId/learning/refine';
  static String clearLearning(int userId) => '/insights/$userId/learning/clear';

  static String sendWhatsApp(int userId) => '/notifications/whatsapp/$userId';
  static String notificationSettings(int userId) =>
      '/notifications/settings/$userId';
}
