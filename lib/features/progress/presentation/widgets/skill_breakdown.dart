import 'package:flutter/material.dart';

import '../../domain/entities/skill_stat.dart';

class SkillBreakdown extends StatelessWidget {
  const SkillBreakdown({super.key, required this.skills});

  final List<SkillStat> skills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Accuracy by skill area',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Text(
                'Skill breakdown appears after you answer tagged questions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            else
              ...skills.map((s) {
                final ratio = (s.accuracyPercent / 100).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.skillArea,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${s.accuracyPercent.toStringAsFixed(0)}%',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: ratio >= 0.7
                              ? Colors.green.shade600
                              : (ratio >= 0.4
                                  ? scheme.primary
                                  : scheme.error),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.correct}/${s.total} correct',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
