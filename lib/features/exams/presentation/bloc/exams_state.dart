part of 'exams_bloc.dart';

abstract class ExamsState extends Equatable {
  const ExamsState();

  @override
  List<Object?> get props => [];
}

class ExamsInitial extends ExamsState {
  const ExamsInitial();
}

class ExamsLoading extends ExamsState {
  const ExamsLoading();
}

class ExamsLoaded extends ExamsState {
  const ExamsLoaded(this.tests);

  final List<MockTest> tests;

  @override
  List<Object?> get props => [tests];
}

class ExamsError extends ExamsState {
  const ExamsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
