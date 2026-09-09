import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_insight.dart';
import '../entities/progress_dashboard.dart';
import '../entities/user_progress.dart';

abstract class ProgressRepository {
  Future<Either<Failure, UserProgress>> getUserProgress();

  Future<Either<Failure, ProgressDashboard>> getProgressDashboard();

  Future<Either<Failure, UserProgress>> recordQuizCompletion({
    required int correctCount,
    required int totalCount,
    Map<String, ({int correct, int total})>? skillDeltas,
  });

  Future<Either<Failure, AiInsight>> refreshAiInsights({
    required ProgressDashboard dashboard,
    bool force = false,
  });
}
