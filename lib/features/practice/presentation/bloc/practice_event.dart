part of 'practice_bloc.dart';

abstract class PracticeEvent extends Equatable {
  const PracticeEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyPractice extends PracticeEvent {
  const LoadDailyPractice({
    required this.examType,
    required this.section,
  });

  final ExamType examType;
  final ExamSection section;

  @override
  List<Object?> get props => [examType, section];
}
