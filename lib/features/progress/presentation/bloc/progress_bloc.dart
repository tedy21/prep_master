import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/usecases/get_user_progress.dart';

part 'progress_event.dart';
part 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc({required GetUserProgress getUserProgress})
      : _getUserProgress = getUserProgress,
        super(const ProgressInitial()) {
    on<LoadUserProgress>(_onLoadUserProgress);
  }

  final GetUserProgress _getUserProgress;

  Future<void> _onLoadUserProgress(
    LoadUserProgress event,
    Emitter<ProgressState> emit,
  ) async {
    emit(const ProgressLoading());
    final result = await _getUserProgress(const NoParams());
    result.fold(
      (failure) => emit(ProgressError(failure.message)),
      (progress) => emit(ProgressLoaded(progress)),
    );
  }
}
