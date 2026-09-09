import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/entities/progress_dashboard.dart';
import '../models/ai_insight_model.dart';

abstract class ProgressAiRemoteDataSource {
  Future<AiInsight> generateInsights({
    required ProgressDashboard dashboard,
    bool force = false,
  });
}

class ProgressAiRemoteDataSourceImpl implements ProgressAiRemoteDataSource {
  ProgressAiRemoteDataSourceImpl(this.firebase);

  final FirebaseService firebase;

  @override
  Future<AiInsight> generateInsights({
    required ProgressDashboard dashboard,
    bool force = false,
  }) async {
    final uid = firebase.uid;
    if (uid == null) throw const AuthException('Not signed in');

    final p = dashboard.progress;
    final skills = dashboard.skillStats
        .map(
          (s) => {
            'skill': s.skillArea,
            'correct': s.correct,
            'total': s.total,
            'accuracy': double.parse(s.accuracyPercent.toStringAsFixed(1)),
          },
        )
        .toList();

    final recentPercents = dashboard.recentSessions
        .take(10)
        .map((s) => double.parse(s.percent.toStringAsFixed(1)))
        .toList();

    try {
      final callable =
          firebase.functions.httpsCallable('generateProgressInsights');
      final result = await callable.call(<String, dynamic>{
        'force': force,
        'stats': {
          'streakDays': p.streakDays,
          'xpPoints': p.xpPoints,
          'level': p.level,
          'sessionsCompleted': p.sessionsCompleted,
          'accuracyPercent':
              double.parse(p.accuracyPercent.toStringAsFixed(1)),
          'skillStats': skills,
          'recentSessionPercents': recentPercents,
        },
      });

      final raw = result.data;
      if (raw is! Map) {
        throw const ServerException('Invalid AI coach response');
      }
      return AiInsightModel.fromCallable(Map<String, dynamic>.from(raw));
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(e.message ?? 'AI coach unavailable');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
