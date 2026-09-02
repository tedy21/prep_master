import 'package:equatable/equatable.dart';

/// Reading passage or listening transcript attached to a question.
enum QuestionContextType {
  none,
  passage,
  transcript;

  static QuestionContextType fromString(String? value) {
    switch (value) {
      case 'passage':
        return QuestionContextType.passage;
      case 'transcript':
        return QuestionContextType.transcript;
      default:
        return QuestionContextType.none;
    }
  }

  String get jsonValue {
    switch (this) {
      case QuestionContextType.passage:
        return 'passage';
      case QuestionContextType.transcript:
        return 'transcript';
      case QuestionContextType.none:
        return 'none';
    }
  }
}

/// Normalized quiz question used across Free APIs + Firestore content.
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    required this.category,
    required this.difficulty,
    this.explanation,
    this.examType,
    this.skillArea,
    this.contextType = QuestionContextType.none,
    this.contextTitle,
    this.contextBody,
    this.contextSetId,
  });

  final String id;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  final String category;
  final String difficulty;
  final String? explanation;
  final String? examType;
  final String? skillArea;
  final QuestionContextType contextType;
  final String? contextTitle;
  final String? contextBody;
  final String? contextSetId;

  bool get hasContext =>
      contextType != QuestionContextType.none &&
      contextBody != null &&
      contextBody!.trim().isNotEmpty;

  List<String> get shuffledOptions {
    final options = [...incorrectAnswers, correctAnswer]..shuffle();
    return options;
  }

  int correctIndexIn(List<String> options) => options.indexOf(correctAnswer);

  QuizQuestion copyWith({
    String? examType,
    String? skillArea,
    QuestionContextType? contextType,
    String? contextTitle,
    String? contextBody,
    String? contextSetId,
  }) {
    return QuizQuestion(
      id: id,
      question: question,
      correctAnswer: correctAnswer,
      incorrectAnswers: incorrectAnswers,
      category: category,
      difficulty: difficulty,
      explanation: explanation,
      examType: examType ?? this.examType,
      skillArea: skillArea ?? this.skillArea,
      contextType: contextType ?? this.contextType,
      contextTitle: contextTitle ?? this.contextTitle,
      contextBody: contextBody ?? this.contextBody,
      contextSetId: contextSetId ?? this.contextSetId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'correctAnswer': correctAnswer,
        'incorrectAnswers': incorrectAnswers,
        'category': category,
        'difficulty': difficulty,
        'explanation': explanation,
        'examType': examType,
        'skillArea': skillArea,
        'contextType': contextType.jsonValue,
        'contextTitle': contextTitle,
        'contextBody': contextBody,
        'contextSetId': contextSetId,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      incorrectAnswers: (json['incorrectAnswers'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      category: json['category'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'medium',
      explanation: json['explanation'] as String?,
      examType: json['examType'] as String?,
      skillArea: json['skillArea'] as String?,
      contextType:
          QuestionContextType.fromString(json['contextType'] as String?),
      contextTitle: json['contextTitle'] as String?,
      contextBody: json['contextBody'] as String?,
      contextSetId: json['contextSetId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        correctAnswer,
        incorrectAnswers,
        category,
        difficulty,
        explanation,
        examType,
        skillArea,
        contextType,
        contextTitle,
        contextBody,
        contextSetId,
      ];
}
