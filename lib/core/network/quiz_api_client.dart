import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../error/exceptions.dart';
import '../models/quiz_question.dart';

/// QuizAPI.io — free tier with API key (500 calls/month).
/// Pass key via `--dart-define=QUIZAPI_KEY=...`
class QuizApiClient {
  QuizApiClient({Dio? dio, String? apiKey})
      : _apiKey = apiKey ?? FreeApiEndpoints.quizApiKey,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: FreeApiEndpoints.quizApiBase,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;
  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<List<QuizQuestion>> fetchQuestions({
    String? category,
    String difficulty = 'Easy',
    int limit = 10,
  }) async {
    if (!isConfigured) {
      throw const ServerException(
        'QUIZAPI_KEY not set. Sign up at quizapi.io and pass '
        '--dart-define=QUIZAPI_KEY=your_key',
      );
    }

    try {
      final res = await _dio.get<List<dynamic>>(
        '/questions',
        queryParameters: {
          'limit': limit,
          'difficulty': difficulty,
          if (category != null) 'category': category,
        },
        options: Options(headers: {'X-Api-Key': _apiKey}),
      );

      final list = res.data ?? [];
      return list.map((raw) {
        final q = raw as Map<String, dynamic>;
        final answers = q['answers'] as Map<String, dynamic>? ?? {};
        final correctMap = q['correct_answers'] as Map<String, dynamic>? ?? {};

        String correct = '';
        final incorrect = <String>[];
        for (final entry in answers.entries) {
          final text = entry.value?.toString();
          if (text == null || text.isEmpty) continue;
          final flagKey = '${entry.key}_correct';
          final isCorrect = correctMap[flagKey]?.toString() == 'true';
          if (isCorrect) {
            correct = text;
          } else {
            incorrect.add(text);
          }
        }

        return QuizQuestion(
          id: 'quizapi-${q['id']}',
          question: q['question'] as String? ?? '',
          correctAnswer: correct,
          incorrectAnswers: incorrect,
          category: q['category'] as String? ?? category ?? 'tech',
          difficulty: q['difficulty'] as String? ?? difficulty,
        );
      }).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'QuizAPI network error');
    }
  }
}
