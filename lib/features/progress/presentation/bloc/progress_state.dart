part of 'progress_bloc.dart';

abstract class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

class ProgressLoaded extends ProgressState {
  const ProgressLoaded(this.dashboard, {this.aiRefreshing = false});

  final ProgressDashboard dashboard;
  final bool aiRefreshing;

  ProgressLoaded copyWith({
    ProgressDashboard? dashboard,
    bool? aiRefreshing,
  }) {
    return ProgressLoaded(
      dashboard ?? this.dashboard,
      aiRefreshing: aiRefreshing ?? this.aiRefreshing,
    );
  }

  @override
  List<Object?> get props => [dashboard, aiRefreshing];
}

class ProgressError extends ProgressState {
  const ProgressError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
