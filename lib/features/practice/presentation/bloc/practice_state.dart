part of 'practice_bloc.dart';

abstract class PracticeState extends Equatable {
  const PracticeState();

  @override
  List<Object?> get props => [];
}

class PracticeInitial extends PracticeState {
  const PracticeInitial();
}

class PracticeLoading extends PracticeState {
  const PracticeLoading();
}

class PracticeLoaded extends PracticeState {
  const PracticeLoaded(this.session);

  final PracticeSession session;

  @override
  List<Object?> get props => [session];
}

class PracticeError extends PracticeState {
  const PracticeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
