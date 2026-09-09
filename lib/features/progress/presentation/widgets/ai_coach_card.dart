import 'package:flutter/material.dart';

import '../../domain/entities/ai_insight.dart';

class AiCoachCard extends StatelessWidget {
  const AiCoachCard({
    super.key,
    required this.insight,
    required this.refreshing,
    required this.onRefresh,
    this.onPracticeWeakArea,
    this.weakAreaLabel,
  });

  final AiInsight insight;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback? onPracticeWeakArea;
  final String? weakAreaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Coach',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (insight.isFallback)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      'Offline tip',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Refresh coach',
                  onPressed: refreshing ? null : onRefresh,
                  icon: refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              insight.headline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (insight.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(insight.summary, style: theme.textTheme.bodyMedium),
            ],
            if (insight.strengths.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Strengths',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              ...insight.strengths.map(
                (s) => _Bullet(text: s, icon: Icons.check_circle_outline),
              ),
            ],
            if (insight.weakAreas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Focus areas',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.tertiary,
                ),
              ),
              const SizedBox(height: 4),
              ...insight.weakAreas.map(
                (s) => _Bullet(text: s, icon: Icons.flag_outlined),
              ),
            ],
            if (insight.nextActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Next steps',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...insight.nextActions.map(
                (s) => _Bullet(text: s, icon: Icons.arrow_right_alt),
              ),
            ],
            if (insight.encouragement.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                insight.encouragement,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
            if (onPracticeWeakArea != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onPracticeWeakArea,
                  child: Text(
                    weakAreaLabel == null
                        ? 'Practice now'
                        : 'Practice $weakAreaLabel',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
