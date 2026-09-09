import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/progress_dashboard.dart';
import '../../domain/usecases/get_progress_dashboard.dart';
import '../../domain/usecases/refresh_ai_insights.dart';

part 'progress_event.dart';
part 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc({
    required GetProgressDashboard getProgressDashboard,
    required RefreshAiInsights refreshAiInsights,
  })  : _getProgressDashboard = getProgressDashboard,
        _refreshAiInsights = refreshAiInsights,
        super(const ProgressInitial()) {
    on<LoadUserProgress>(_onLoadUserProgress);
    on<RefreshProgressAiCoach>(_onRefreshAiCoach);
  }

  final GetProgressDashboard _getProgressDashboard;
  final RefreshAiInsights _refreshAiInsights;

  Future<void> _onLoadUserProgress(
    LoadUserProgress event,
    Emitter<ProgressState> emit,
  ) async {
    emit(const ProgressLoading());
    final result = await _getProgressDashboard(const NoParams());
    await result.fold(
      (failure) async => emit(ProgressError(failure.message)),
      (dashboard) async {
        emit(ProgressLoaded(dashboard));
        if (event.refreshAi &&
            (dashboard.aiInsight == null ||
                dashboard.aiInsight!.isStale ||
                dashboard.aiInsight!.isFallback) &&
            dashboard.progress.sessionsCompleted > 0) {
          add(const RefreshProgressAiCoach());
        }
      },
    );
  }

  Future<void> _onRefreshAiCoach(
    RefreshProgressAiCoach event,
    Emitter<ProgressState> emit,
  ) async {
    final current = state;
    if (current is! ProgressLoaded) return;

    emit(current.copyWith(aiRefreshing: true));
    final result = await _refreshAiInsights(
      RefreshAiInsightsParams(
        dashboard: current.dashboard,
        force: event.force,
      ),
    );
    result.fold(
      (_) => emit(current.copyWith(aiRefreshing: false)),
      (insight) => emit(
        ProgressLoaded(
          current.dashboard.copyWith(aiInsight: insight),
          aiRefreshing: false,
        ),
      ),
    );
  }
}
