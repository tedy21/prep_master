/// API endpoint paths (relative to base URL).
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.prepmaster.app/v1',
  );

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  // Practice & exams
  static const String dailyPractice = '/practice/daily';
  static const String quizzes = '/practice/quizzes';
  static const String mockTests = '/exams/mocks';
  static const String submitSession = '/practice/sessions';

  // Progress
  static const String progress = '/progress';
  static const String errorLog = '/progress/errors';
  static const String achievements = '/progress/achievements';

  // Vocabulary
  static const String vocabulary = '/vocabulary';
  static const String flashcards = '/vocabulary/flashcards';

  // College guides
  static const String collegeGuides = '/college/guides';
  static const String collegeChecklist = '/college/checklist';
}
