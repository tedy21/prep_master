import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/mock_test_model.dart';

abstract class ExamLocalDataSource {
  Future<List<MockTestModel>> getCachedMockTests(ExamType examType);
  Future<void> cacheMockTests(ExamType examType, List<MockTestModel> tests);
}

class ExamLocalDataSourceImpl implements ExamLocalDataSource {
  ExamLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static String _key(ExamType type) => 'mock_tests_${type.name}';

  @override
  Future<List<MockTestModel>> getCachedMockTests(ExamType examType) async {
    try {
      final raw = _prefs.getString(_key(examType));
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MockTestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheMockTests(
    ExamType examType,
    List<MockTestModel> tests,
  ) async {
    try {
      final encoded = jsonEncode(tests.map((t) => t.toJson()).toList());
      await _prefs.setString(_key(examType), encoded);
    } catch (_) {
      throw const CacheException();
    }
  }
}
