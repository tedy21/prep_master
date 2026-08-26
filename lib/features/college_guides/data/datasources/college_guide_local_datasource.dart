import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/college_guide_model.dart';

abstract class CollegeGuideLocalDataSource {
  Future<List<CollegeGuideModel>> getCachedGuides();
  Future<void> cacheGuides(List<CollegeGuideModel> guides);
}

class CollegeGuideLocalDataSourceImpl implements CollegeGuideLocalDataSource {
  CollegeGuideLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'college_guides';

  @override
  Future<List<CollegeGuideModel>> getCachedGuides() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CollegeGuideModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheGuides(List<CollegeGuideModel> guides) async {
    try {
      final encoded = jsonEncode(guides.map((g) => g.toJson()).toList());
      await _prefs.setString(_key, encoded);
    } catch (_) {
      throw const CacheException();
    }
  }
}
