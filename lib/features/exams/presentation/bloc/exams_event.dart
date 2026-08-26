part of 'exams_bloc.dart';

abstract class ExamsEvent extends Equatable {
  const ExamsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMockTests extends ExamsEvent {
  const LoadMockTests(this.examType);

  final ExamType examType;

  @override
  List<Object?> get props => [examType];
}
