part of 'quiz_session_bloc.dart';

abstract class QuizSessionState extends Equatable {
  const QuizSessionState();

  @override
  List<Object?> get props => [];
}

class QuizSessionInitial extends QuizSessionState {
  const QuizSessionInitial();
}

class QuizSessionLoading extends QuizSessionState {
  const QuizSessionLoading();
}

class QuizSessionError extends QuizSessionState {
  const QuizSessionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class QuizSessionActive extends QuizSessionState {
  const QuizSessionActive({
    required this.title,
    required this.examType,
    this.section,
    this.mockTestId,
    required this.questions,
    required this.currentIndex,
    required this.selectedOption,
    required this.answers,
    required this.targetCount,
    this.adaptive = false,
    this.currentDifficulty,
    this.timeLimitMinutes,
  });

  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final String? selectedOption;
  final List<String?> answers;

  final int targetCount;
  final bool adaptive;
  final String? currentDifficulty;
  final int? timeLimitMinutes;

  QuizQuestion get currentQuestion => questions[currentIndex];

  int get displayTotal => adaptive ? targetCount : questions.length;

  bool get isLastPlanned => currentIndex >= targetCount - 1;

  QuizSessionActive copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    String? selectedOption,
    List<String?>? answers,
    int? targetCount,
    bool? adaptive,
    String? currentDifficulty,
    int? timeLimitMinutes,
    bool clearSelected = false,
  }) {
    return QuizSessionActive(
      title: title,
      examType: examType,
      section: section,
      mockTestId: mockTestId,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption:
          clearSelected ? null : (selectedOption ?? this.selectedOption),
      answers: answers ?? this.answers,
      targetCount: targetCount ?? this.targetCount,
      adaptive: adaptive ?? this.adaptive,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
    );
  }

  @override
  List<Object?> get props => [
        title,
        examType,
        section,
        mockTestId,
        questions,
        currentIndex,
        selectedOption,
        answers,
        targetCount,
        adaptive,
        currentDifficulty,
        timeLimitMinutes,
      ];
}

class QuizSessionFinished extends QuizSessionState {
  const QuizSessionFinished({
    required this.title,
    required this.examType,
    this.section,
    this.mockTestId,
    required this.questions,
    required this.answers,
    this.timedOut = false,
  });

  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final List<QuizQuestion> questions;
  final List<String?> answers;
  final bool timedOut;

  int get score {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].correctAnswer) correct++;
    }
    return correct;
  }

  double get percent => questions.isEmpty ? 0 : score / questions.length * 100;

  Map<String, ({int correct, int total})> get topicBreakdown {
    final map = <String, ({int correct, int total})>{};
    for (var i = 0; i < questions.length; i++) {
      final skill = (questions[i].skillArea ?? questions[i].category).trim();
      if (skill.isEmpty) continue;
      final prev = map[skill] ?? (correct: 0, total: 0);
      final ok = answers[i] == questions[i].correctAnswer;
      map[skill] = (
        correct: prev.correct + (ok ? 1 : 0),
        total: prev.total + 1,
      );
    }
    return map;
  }

  @override
  List<Object?> get props =>
      [title, examType, section, mockTestId, questions, answers, timedOut];
}
