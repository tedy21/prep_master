import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_progress_model.dart';

abstract class ProgressLocalDataSource {
  Future<UserProgressModel?> getCachedProgress();
  Future<void> cacheProgress(UserProgressModel progress);
}

class ProgressLocalDataSourceImpl implements ProgressLocalDataSource {
  ProgressLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'user_progress';

  @override
  Future<UserProgressModel?> getCachedProgress() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return null;
      return UserProgressModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheProgress(UserProgressModel progress) async {
    try {
      await _prefs.setString(_key, jsonEncode(progress.toJson()));
    } catch (_) {
      throw const CacheException();
    }
  }
}
