import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../practice/domain/usecases/get_quiz_questions.dart';
import '../../domain/entities/quiz_session_args.dart';

part 'quiz_session_event.dart';
part 'quiz_session_state.dart';

class QuizSessionBloc extends Bloc<QuizSessionEvent, QuizSessionState> {
  QuizSessionBloc({required GetQuizQuestions getQuizQuestions})
      : _getQuizQuestions = getQuizQuestions,
        super(const QuizSessionInitial()) {
    on<StartQuizSession>(_onStart);
    on<SelectAnswer>(_onSelect);
    on<NextQuestion>(_onNext);
  }

  final GetQuizQuestions _getQuizQuestions;

  Future<void> _onStart(
    StartQuizSession event,
    Emitter<QuizSessionState> emit,
  ) async {
    emit(const QuizSessionLoading());
    final result = await _getQuizQuestions(
      GetQuizQuestionsParams(
        examType: event.args.examType,
        section: event.args.section,
        amount: event.args.questionCount,
        mockTestId: event.args.mockTestId,
      ),
    );
    result.fold(
      (failure) => emit(QuizSessionError(failure.message)),
      (questions) {
        if (questions.isEmpty) {
          emit(const QuizSessionError('No questions found'));
          return;
        }
        emit(QuizSessionActive(
          title: event.args.title,
          examType: event.args.examType,
          questions: questions,
          currentIndex: 0,
          selectedOption: null,
          answers: List.filled(questions.length, null),
        ));
      },
    );
  }

  void _onSelect(SelectAnswer event, Emitter<QuizSessionState> emit) {
    final state = this.state;
    if (state is! QuizSessionActive) return;
    emit(state.copyWith(selectedOption: event.option));
  }

  void _onNext(NextQuestion event, Emitter<QuizSessionState> emit) {
    final state = this.state;
    if (state is! QuizSessionActive) return;
    if (state.selectedOption == null) return;

    final answers = List<String?>.from(state.answers);
    answers[state.currentIndex] = state.selectedOption;

    final isLast = state.currentIndex >= state.questions.length - 1;
    if (isLast) {
      emit(QuizSessionFinished(
        title: state.title,
        examType: state.examType,
        questions: state.questions,
        answers: answers,
      ));
      return;
    }

    emit(state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedOption: null,
      answers: answers,
    ));
  }
}
