/// KiryanaAI API Endpoint Constants
/// These are pre-defined for future backend integration.
/// Currently not in use — all data comes from MockDataSource.
abstract class ApiEndpoints {
  // Base
  static const String baseUrl = 'https://api.kiryana.ai/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Voice / AI
  static const String transcribe = '/ai/transcribe';
  static const String parseTransaction = '/ai/parse-transaction';

  // Transactions
  static const String transactions = '/transactions';
  static const String transactionById = '/transactions/{id}';
  static const String transactionsByDate = '/transactions/by-date';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String weeklyReport = '/dashboard/weekly';

  // Insights
  static const String insights = '/insights';
  static const String recommendations = '/insights/recommendations';

  // Products
  static const String products = '/products';
  static const String topProducts = '/products/top-selling';

  // User
  static const String userProfile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String notifications = '/users/notifications';
}
