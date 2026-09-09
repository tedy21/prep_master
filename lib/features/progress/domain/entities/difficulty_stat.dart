import 'package:equatable/equatable.dart';

class DifficultyStat extends Equatable {
  const DifficultyStat({
    required this.difficulty,
    required this.correct,
    required this.total,
  });

  final String difficulty;
  final int correct;
  final int total;

  double get accuracyPercent => total == 0 ? 0 : (correct / total) * 100;

  @override
  List<Object?> get props => [difficulty, correct, total];
}
