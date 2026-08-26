import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/practice_session_model.dart';

abstract class PracticeLocalDataSource {
  Future<PracticeSessionModel?> getCachedDailyPractice(ExamType examType);
  Future<void> cacheDailyPractice(PracticeSessionModel session);
}

class PracticeLocalDataSourceImpl implements PracticeLocalDataSource {
  PracticeLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static String _key(ExamType type) => 'daily_practice_${type.name}';

  @override
  Future<PracticeSessionModel?> getCachedDailyPractice(
    ExamType examType,
  ) async {
    try {
      final raw = _prefs.getString(_key(examType));
      if (raw == null) return null;
      return PracticeSessionModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheDailyPractice(PracticeSessionModel session) async {
    try {
      await _prefs.setString(
        _key(session.examType),
        jsonEncode(session.toJson()),
      );
    } catch (_) {
      throw const CacheException();
    }
  }
}
