part of 'college_guides_bloc.dart';

abstract class CollegeGuidesEvent extends Equatable {
  const CollegeGuidesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCollegeGuides extends CollegeGuidesEvent {
  const LoadCollegeGuides({this.category});

  final GuideCategory? category;

  @override
  List<Object?> get props => [category];
}
