/// Firestore collection / document path helpers.
abstract final class FirestorePaths {
  static const users = 'users';
  static const questions = 'questions';
  static const quizQuestions = 'quiz_questions';
  static const contentMeta = 'content_meta';
  static const leaderboard = 'leaderboard';
  static const vocabulary = 'vocabulary';
  static const collegeGuides = 'college_guides';
  static const mockTests = 'mock_tests';

  static const contentCatalog = '$contentMeta/catalog';

  static String user(String uid) => '$users/$uid';
  static String userProgress(String uid) => '$users/$uid/progress/summary';
  static String userSessions(String uid) => '$users/$uid/sessionHistory';
  static String userSession(String uid, String sessionId) =>
      '$users/$uid/sessionHistory/$sessionId';

  static String ieltsListening(String id) => '$questions/ielts/listening/$id';
  static String ieltsReading(String id) => '$questions/ielts/reading/$id';
  static String ieltsWriting(String id) => '$questions/ielts/writing/$id';
  static String ieltsSpeaking(String id) => '$questions/ielts/speaking/$id';
  static String satMath(String id) => '$questions/sat/math/$id';
  static String satReadingWriting(String id) =>
      '$questions/sat/readingWriting/$id';

  static String vocabIelts(String id) => '$vocabulary/ielts/words/$id';
  static String vocabSat(String id) => '$vocabulary/sat/words/$id';

  static String globalLeaderboardEntry(String uid) =>
      '$leaderboard/global/entries/$uid';
}

/// Free public trivia API endpoints (no Firebase).
abstract final class FreeApiEndpoints {
  static const openTriviaBase = 'https://opentdb.com';
  static const openTriviaQuiz = '$openTriviaBase/api.php';
  static const openTriviaToken = '$openTriviaBase/api_token.php';

  static const triviaApiBase = 'https://the-trivia-api.com/v2';
  static const triviaApiQuestions = '$triviaApiBase/questions';

  static const quizApiBase = 'https://quizapi.io/api/v1';
  static const quizApiQuestions = '$quizApiBase/questions';

  /// Pass at build time: `--dart-define=QUIZAPI_KEY=your_key`
  static const quizApiKey = String.fromEnvironment('QUIZAPI_KEY');
}
