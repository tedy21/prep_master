import 'package:equatable/equatable.dart';

class AiInsight extends Equatable {
  const AiInsight({
    required this.headline,
    required this.summary,
    required this.strengths,
    required this.weakAreas,
    required this.nextActions,
    required this.encouragement,
    this.generatedAt,
    this.model,
    this.isFallback = false,
  });

  final String headline;
  final String summary;
  final List<String> strengths;
  final List<String> weakAreas;
  final List<String> nextActions;
  final String encouragement;
  final DateTime? generatedAt;
  final String? model;
  final bool isFallback;

  bool get isStale {
    if (generatedAt == null) return true;
    return DateTime.now().difference(generatedAt!) > const Duration(hours: 6);
  }

  factory AiInsight.fallback({
    required String headline,
    required String summary,
    required List<String> strengths,
    required List<String> weakAreas,
    required List<String> nextActions,
    required String encouragement,
  }) {
    return AiInsight(
      headline: headline,
      summary: summary,
      strengths: strengths,
      weakAreas: weakAreas,
      nextActions: nextActions,
      encouragement: encouragement,
      generatedAt: DateTime.now(),
      model: 'local-fallback',
      isFallback: true,
    );
  }

  @override
  List<Object?> get props => [
        headline,
        summary,
        strengths,
        weakAreas,
        nextActions,
        encouragement,
        generatedAt,
        model,
        isFallback,
      ];
}
