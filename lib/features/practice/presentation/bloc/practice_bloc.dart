import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/exam_section.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/usecases/get_daily_practice.dart';

part 'practice_event.dart';
part 'practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc({required GetDailyPractice getDailyPractice})
      : _getDailyPractice = getDailyPractice,
        super(const PracticeInitial()) {
    on<LoadDailyPractice>(_onLoadDailyPractice);
  }

  final GetDailyPractice _getDailyPractice;

  Future<void> _onLoadDailyPractice(
    LoadDailyPractice event,
    Emitter<PracticeState> emit,
  ) async {
    emit(const PracticeLoading());
    final result = await _getDailyPractice(
      GetDailyPracticeParams(
        examType: event.examType,
        section: event.section,
      ),
    );
    result.fold(
      (failure) => emit(PracticeError(failure.message)),
      (session) => emit(PracticeLoaded(session)),
    );
  }
}
