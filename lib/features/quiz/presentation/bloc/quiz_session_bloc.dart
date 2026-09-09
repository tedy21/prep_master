import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/question_difficulty.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../practice/domain/usecases/get_adaptive_pools.dart';
import '../../../practice/domain/usecases/get_quiz_questions.dart';
import '../../domain/entities/quiz_session_args.dart';

part 'quiz_session_event.dart';
part 'quiz_session_state.dart';

class QuizSessionBloc extends Bloc<QuizSessionEvent, QuizSessionState> {
  QuizSessionBloc({
    required GetQuizQuestions getQuizQuestions,
    required GetAdaptivePools getAdaptivePools,
  })  : _getQuizQuestions = getQuizQuestions,
        _getAdaptivePools = getAdaptivePools,
        super(const QuizSessionInitial()) {
    on<StartQuizSession>(_onStart);
    on<SelectAnswer>(_onSelect);
    on<NextQuestion>(_onNext);
    on<ForceFinishQuiz>(_onForceFinish);
  }

  final GetQuizQuestions _getQuizQuestions;
  final GetAdaptivePools _getAdaptivePools;

  Map<String, List<QuizQuestion>> _pools = {};
  final Set<String> _usedIds = {};

  Future<void> _onStart(
    StartQuizSession event,
    Emitter<QuizSessionState> emit,
  ) async {
    emit(const QuizSessionLoading());
    _pools = {};
    _usedIds.clear();

    final args = event.args;
    if (args.adaptive && args.section != null && args.mockTestId == null) {
      await _startAdaptive(args, emit);
      return;
    }

    final result = await _getQuizQuestions(
      GetQuizQuestionsParams(
        examType: args.examType,
        section: args.section,
        amount: args.questionCount,
        mockTestId: args.mockTestId,
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
          title: args.title,
          examType: args.examType,
          section: args.section,
          mockTestId: args.mockTestId,
          questions: questions,
          currentIndex: 0,
          selectedOption: null,
          answers: List.filled(questions.length, null),
          targetCount: questions.length,
          adaptive: false,
          timeLimitMinutes: args.timeLimitMinutes,
        ));
      },
    );
  }

  Future<void> _startAdaptive(
    QuizSessionArgs args,
    Emitter<QuizSessionState> emit,
  ) async {
    final result = await _getAdaptivePools(
      GetAdaptivePoolsParams(
        examType: args.examType,
        section: args.section!,
        perBucket: (args.questionCount * 2).clamp(8, 20),
      ),
    );

    await result.fold(
      (failure) async => emit(QuizSessionError(failure.message)),
      (pools) async {
        _pools = {
          for (final e in pools.entries)
            QuestionDifficulty.normalize(e.key): List.of(e.value),
        };

        final available = _pools.values.fold<int>(0, (n, list) => n + list.length);
        if (available == 0) {
          emit(
            const QuizSessionError(
              'No adaptive questions available for this section yet.',
            ),
          );
          return;
        }

        final preferred =
            QuestionDifficulty.normalize(args.initialDifficulty);
        QuizQuestion? first;
        var difficulty = preferred;
        for (final candidate in _fallbackOrder(preferred)) {
          first = _takeFromPools(candidate);
          if (first != null) {
            difficulty = QuestionDifficulty.normalize(first.difficulty);
            break;
          }
        }

        if (first == null) {
          emit(
            const QuizSessionError(
              'No adaptive questions available for this section yet.',
            ),
          );
          return;
        }

        // Don't plan more questions than we actually have in the pools.
        final remainingAfterFirst = available - 1;
        final targetCount =
            (1 + remainingAfterFirst).clamp(1, args.questionCount);

        emit(QuizSessionActive(
          title: args.title,
          examType: args.examType,
          section: args.section,
          mockTestId: null,
          questions: [first],
          currentIndex: 0,
          selectedOption: null,
          answers: [null],
          targetCount: targetCount,
          adaptive: true,
          currentDifficulty: difficulty,
          timeLimitMinutes: null,
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

    final current = state.currentQuestion;
    final correct = state.selectedOption == current.correctAnswer;

    if (state.isLastPlanned) {
      emit(QuizSessionFinished(
        title: state.title,
        examType: state.examType,
        section: state.section,
        mockTestId: state.mockTestId,
        questions: state.questions,
        answers: answers,
      ));
      return;
    }

    if (!state.adaptive) {
      emit(state.copyWith(
        currentIndex: state.currentIndex + 1,
        answers: answers,
        clearSelected: true,
      ));
      return;
    }

    var nextDiff = correct
        ? QuestionDifficulty.harder(state.currentDifficulty ?? current.difficulty)
        : QuestionDifficulty.easier(state.currentDifficulty ?? current.difficulty);

    var next = _takeFromPools(nextDiff, preferSetId: current.contextSetId);
    if (next == null) {
      // Nearest difficulty, then any remaining.
      for (final fallback in _fallbackOrder(nextDiff)) {
        next = _takeFromPools(fallback, preferSetId: current.contextSetId);
        if (next != null) {
          nextDiff = fallback;
          break;
        }
      }
    }

    if (next == null) {
      emit(QuizSessionFinished(
        title: state.title,
        examType: state.examType,
        section: state.section,
        mockTestId: state.mockTestId,
        questions: state.questions,
        answers: answers,
      ));
      return;
    }

    final questions = List<QuizQuestion>.from(state.questions)..add(next);
    answers.add(null);

    emit(state.copyWith(
      questions: questions,
      answers: answers,
      currentIndex: state.currentIndex + 1,
      currentDifficulty: QuestionDifficulty.normalize(next.difficulty),
      clearSelected: true,
    ));
  }

  void _onForceFinish(ForceFinishQuiz event, Emitter<QuizSessionState> emit) {
    final state = this.state;
    if (state is! QuizSessionActive) return;

    final answers = List<String?>.from(state.answers);
    if (state.selectedOption != null) {
      answers[state.currentIndex] = state.selectedOption;
    }

    emit(QuizSessionFinished(
      title: state.title,
      examType: state.examType,
      section: state.section,
      mockTestId: state.mockTestId,
      questions: state.questions,
      answers: answers,
      timedOut: true,
    ));
  }

  QuizQuestion? _takeFromPools(
    String difficulty, {
    String? preferSetId,
  }) {
    final key = QuestionDifficulty.normalize(difficulty);
    final bucket = _pools[key];
    if (bucket == null || bucket.isEmpty) return null;

    int index = -1;
    if (preferSetId != null && preferSetId.isNotEmpty) {
      index = bucket.indexWhere(
        (q) => !_usedIds.contains(q.id) && q.contextSetId == preferSetId,
      );
    }
    if (index < 0) {
      index = bucket.indexWhere((q) => !_usedIds.contains(q.id));
    }
    if (index < 0) return null;
    final q = bucket.removeAt(index);
    _usedIds.add(q.id);
    return q;
  }

  List<String> _fallbackOrder(String preferred) {
    final rank = QuestionDifficulty.rank(preferred);
    final others = QuestionDifficulty.all
        .where((d) => d != preferred)
        .toList()
      ..sort(
        (a, b) => (QuestionDifficulty.rank(a) - rank)
            .abs()
            .compareTo((QuestionDifficulty.rank(b) - rank).abs()),
      );
    return [preferred, ...others];
  }
}
