import 'package:equatable/equatable.dart';

class QuizQuestionOutcome extends Equatable {
  const QuizQuestionOutcome({
    required this.questionId,
    this.skillArea,
    this.difficulty,
    required this.isCorrect,
    this.selectedAnswer,
    required this.correctAnswer,
  });

  final String questionId;
  final String? skillArea;
  final String? difficulty;
  final bool isCorrect;
  final String? selectedAnswer;
  final String correctAnswer;

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        if (skillArea != null) 'skillArea': skillArea,
        if (difficulty != null) 'difficulty': difficulty,
        'isCorrect': isCorrect,
        if (selectedAnswer != null) 'selectedAnswer': selectedAnswer,
        'correctAnswer': correctAnswer,
      };

  factory QuizQuestionOutcome.fromMap(Map<String, dynamic> map) {
    return QuizQuestionOutcome(
      questionId: map['questionId'] as String? ?? '',
      skillArea: map['skillArea'] as String?,
      difficulty: map['difficulty'] as String?,
      isCorrect: map['isCorrect'] as bool? ?? false,
      selectedAnswer: map['selectedAnswer'] as String?,
      correctAnswer: map['correctAnswer'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        questionId,
        skillArea,
        difficulty,
        isCorrect,
        selectedAnswer,
        correctAnswer,
      ];
}
