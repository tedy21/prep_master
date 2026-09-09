part of 'progress_bloc.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProgress extends ProgressEvent {
  const LoadUserProgress({this.refreshAi = true});

  final bool refreshAi;

  @override
  List<Object?> get props => [refreshAi];
}

class RefreshProgressAiCoach extends ProgressEvent {
  const RefreshProgressAiCoach({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}
