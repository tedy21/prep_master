import '../../domain/entities/ai_insight.dart';

class AiInsightModel extends AiInsight {
  const AiInsightModel({
    required super.headline,
    required super.summary,
    required super.strengths,
    required super.weakAreas,
    required super.nextActions,
    required super.encouragement,
    super.generatedAt,
    super.model,
    super.isFallback,
  });

  factory AiInsightModel.fromFirestore(Map<String, dynamic> data) {
    return AiInsightModel(
      headline: data['headline'] as String? ?? 'Your study coach',
      summary: data['summary'] as String? ?? '',
      strengths: _asStringList(data['strengths']),
      weakAreas: _asStringList(data['weakAreas']),
      nextActions: _asStringList(data['nextActions']),
      encouragement: data['encouragement'] as String? ?? '',
      generatedAt: _parseDate(data['generatedAt']),
      model: data['model'] as String?,
      isFallback: data['isFallback'] as bool? ?? false,
    );
  }

  factory AiInsightModel.fromCallable(Map<String, dynamic> data) {
    return AiInsightModel.fromFirestore(data);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return (raw as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  AiInsight toEntity() => this;
}
