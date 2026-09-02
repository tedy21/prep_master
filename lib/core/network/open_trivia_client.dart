import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';

import '../constants/api_endpoints.dart';
import '../error/exceptions.dart';
import '../models/quiz_question.dart';

/// Open Trivia DB — free, no API key.
/// Docs: https://opentdb.com/api_config.php
class OpenTriviaClient {
  OpenTriviaClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: FreeApiEndpoints.openTriviaBase,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;
  final _unescape = HtmlUnescape();
  String? _sessionToken;

  Future<String> requestSessionToken() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api_token.php',
      queryParameters: {'command': 'request'},
    );
    final token = res.data?['token'] as String?;
    if (token == null) throw const ServerException('Failed to get OpenTDB token');
    _sessionToken = token;
    return token;
  }

  /// [category] OpenTDB ids: 9=General, 10=Books, 17=Science, 23=History…
  Future<List<QuizQuestion>> fetchQuestions({
    int amount = 10,
    int? category,
    String difficulty = 'medium',
    String type = 'multiple',
    bool useToken = true,
  }) async {
    try {
      if (useToken && _sessionToken == null) {
        await requestSessionToken();
      }

      final params = <String, dynamic>{
        'amount': amount.clamp(1, 50),
        'difficulty': difficulty,
        'type': type,
        if (category != null) 'category': category,
        if (useToken && _sessionToken != null) 'token': _sessionToken,
      };

      final res = await _dio.get<Map<String, dynamic>>(
        '/api.php',
        queryParameters: params,
      );

      final code = res.data?['response_code'] as int? ?? 1;
      if (code == 4) {
        // Token empty — reset and retry once.
        await _dio.get('/api_token.php', queryParameters: {
          'command': 'reset',
          'token': _sessionToken,
        });
        return fetchQuestions(
          amount: amount,
          category: category,
          difficulty: difficulty,
          type: type,
          useToken: useToken,
        );
      }
      if (code != 0) {
        throw ServerException('OpenTDB response_code=$code');
      }

      final results = res.data?['results'] as List<dynamic>? ?? [];
      return results.asMap().entries.map((e) {
        final q = e.value as Map<String, dynamic>;
        return QuizQuestion(
          id: 'opentdb-${e.key}-${q['question'].hashCode}',
          question: _unescape.convert(q['question'] as String),
          correctAnswer: _unescape.convert(q['correct_answer'] as String),
          incorrectAnswers: (q['incorrect_answers'] as List<dynamic>)
              .map((a) => _unescape.convert(a as String))
              .toList(),
          category: q['category'] as String? ?? 'General',
          difficulty: q['difficulty'] as String? ?? difficulty,
        );
      }).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'OpenTDB network error');
    }
  }
}
