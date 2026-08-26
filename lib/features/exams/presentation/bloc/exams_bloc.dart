import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/mock_test.dart';
import '../../domain/usecases/get_mock_tests.dart';

part 'exams_event.dart';
part 'exams_state.dart';

class ExamsBloc extends Bloc<ExamsEvent, ExamsState> {
  ExamsBloc({required GetMockTests getMockTests})
      : _getMockTests = getMockTests,
        super(const ExamsInitial()) {
    on<LoadMockTests>(_onLoadMockTests);
  }

  final GetMockTests _getMockTests;

  Future<void> _onLoadMockTests(
    LoadMockTests event,
    Emitter<ExamsState> emit,
  ) async {
    emit(const ExamsLoading());
    final result = await _getMockTests(
      GetMockTestsParams(examType: event.examType),
    );
    result.fold(
      (failure) => emit(ExamsError(failure.message)),
      (tests) => emit(ExamsLoaded(tests)),
    );
  }
}
