part of 'college_guides_bloc.dart';

abstract class CollegeGuidesState extends Equatable {
  const CollegeGuidesState();

  @override
  List<Object?> get props => [];
}

class CollegeGuidesInitial extends CollegeGuidesState {
  const CollegeGuidesInitial();
}

class CollegeGuidesLoading extends CollegeGuidesState {
  const CollegeGuidesLoading();
}

class CollegeGuidesLoaded extends CollegeGuidesState {
  const CollegeGuidesLoaded(this.guides);

  final List<CollegeGuide> guides;

  @override
  List<Object?> get props => [guides];
}

class CollegeGuidesError extends CollegeGuidesState {
  const CollegeGuidesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
