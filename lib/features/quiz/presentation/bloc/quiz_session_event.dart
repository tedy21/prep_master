part of 'quiz_session_bloc.dart';

abstract class QuizSessionEvent extends Equatable {
  const QuizSessionEvent();

  @override
  List<Object?> get props => [];
}

class StartQuizSession extends QuizSessionEvent {
  const StartQuizSession(this.args);

  final QuizSessionArgs args;

  @override
  List<Object?> get props => [args];
}

class SelectAnswer extends QuizSessionEvent {
  const SelectAnswer(this.option);

  final String option;

  @override
  List<Object?> get props => [option];
}

class NextQuestion extends QuizSessionEvent {
  const NextQuestion();
}
