import 'package:equatable/equatable.dart';

class SkillStat extends Equatable {
  const SkillStat({
    required this.skillArea,
    required this.correct,
    required this.total,
  });

  final String skillArea;
  final int correct;
  final int total;

  double get accuracyPercent => total == 0 ? 0 : (correct / total) * 100;

  @override
  List<Object?> get props => [skillArea, correct, total];
}
