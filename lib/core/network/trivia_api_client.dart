import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../error/exceptions.dart';
import '../models/quiz_question.dart';

/// The Trivia API — free for non-commercial use, no key required.
/// Docs: https://the-trivia-api.com/docs/v2/
class TriviaApiClient {
  TriviaApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: FreeApiEndpoints.triviaApiBase,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;

  Future<List<QuizQuestion>> fetchQuestions({
    int limit = 10,
    String difficulties = 'medium',
    String? categories,
    String? region,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/questions',
        queryParameters: {
          'limit': limit.clamp(1, 50),
          'difficulties': difficulties,
          if (categories != null) 'categories': categories,
          if (region != null) 'region': region,
        },
      );

      final list = res.data ?? [];
      return list.map((raw) {
        final q = raw as Map<String, dynamic>;
        final incorrect = (q['incorrectAnswers'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        return QuizQuestion(
          id: q['id'] as String? ?? 'trivia-${q.hashCode}',
          question: q['question'] is Map
              ? (q['question'] as Map)['text'] as String? ?? ''
              : q['question']?.toString() ?? '',
          correctAnswer: q['correctAnswer'] as String? ?? '',
          incorrectAnswers: incorrect,
          category: (q['category'] as String?) ?? 'general',
          difficulty: (q['difficulty'] as String?) ?? difficulties,
        );
      }).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Trivia API network error');
    }
  }
}
