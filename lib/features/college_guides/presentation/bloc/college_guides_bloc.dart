import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/college_guide.dart';
import '../../domain/usecases/get_college_guides.dart';

part 'college_guides_event.dart';
part 'college_guides_state.dart';

class CollegeGuidesBloc extends Bloc<CollegeGuidesEvent, CollegeGuidesState> {
  CollegeGuidesBloc({required GetCollegeGuides getCollegeGuides})
      : _getCollegeGuides = getCollegeGuides,
        super(const CollegeGuidesInitial()) {
    on<LoadCollegeGuides>(_onLoadCollegeGuides);
  }

  final GetCollegeGuides _getCollegeGuides;

  Future<void> _onLoadCollegeGuides(
    LoadCollegeGuides event,
    Emitter<CollegeGuidesState> emit,
  ) async {
    emit(const CollegeGuidesLoading());
    final result = await _getCollegeGuides(
      GetCollegeGuidesParams(category: event.category),
    );
    result.fold(
      (failure) => emit(CollegeGuidesError(failure.message)),
      (guides) => emit(CollegeGuidesLoaded(guides)),
    );
  }
}
