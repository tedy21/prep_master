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
  });

  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final String? selectedOption;
  final List<String?> answers;

  QuizQuestion get currentQuestion => questions[currentIndex];

  QuizSessionActive copyWith({
    int? currentIndex,
    String? selectedOption,
    List<String?>? answers,
  }) {
    return QuizSessionActive(
      title: title,
      examType: examType,
      section: section,
      mockTestId: mockTestId,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: selectedOption,
      answers: answers ?? this.answers,
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
  });

  final String title;
  final ExamType examType;
  final ExamSection? section;
  final String? mockTestId;
  final List<QuizQuestion> questions;
  final List<String?> answers;

  int get score {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].correctAnswer) correct++;
    }
    return correct;
  }

  double get percent => questions.isEmpty ? 0 : score / questions.length * 100;

  @override
  List<Object?> get props =>
      [title, examType, section, mockTestId, questions, answers];
}
