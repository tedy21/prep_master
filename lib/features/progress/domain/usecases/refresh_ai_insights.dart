import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ai_insight.dart';
import '../entities/progress_dashboard.dart';
import '../repositories/progress_repository.dart';

class RefreshAiInsights
    implements UseCase<AiInsight, RefreshAiInsightsParams> {
  RefreshAiInsights(this._repository);

  final ProgressRepository _repository;

  @override
  Future<Either<Failure, AiInsight>> call(RefreshAiInsightsParams params) {
    return _repository.refreshAiInsights(
      dashboard: params.dashboard,
      force: params.force,
    );
  }
}

class RefreshAiInsightsParams extends Equatable {
  const RefreshAiInsightsParams({
    required this.dashboard,
    this.force = false,
  });

  final ProgressDashboard dashboard;
  final bool force;

  @override
  List<Object?> get props => [dashboard, force];
}
