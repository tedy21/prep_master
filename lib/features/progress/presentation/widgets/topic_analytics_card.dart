import 'package:flutter/material.dart';

import '../../../../core/constants/question_difficulty.dart';
import '../../domain/entities/difficulty_stat.dart';
import '../../domain/entities/progress_dashboard.dart';
import '../../domain/entities/skill_stat.dart';

class TopicAnalyticsCard extends StatelessWidget {
  const TopicAnalyticsCard({super.key, required this.dashboard});

  final ProgressDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final skills = dashboard.skillStats;
    final diffs = dashboard.difficultyStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic analytics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Accuracy, attempts, and recent trend by skill',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Text(
                'Complete adaptive or section practice to unlock topic analytics.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            else
              ...skills.map((s) => _TopicRow(skill: s, dashboard: dashboard)),
            if (diffs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'By difficulty',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: diffs.map((d) => _DiffChip(stat: d)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.skill, required this.dashboard});

  final SkillStat skill;
  final ProgressDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recent = dashboard.recentSkillAccuracy(skill.skillArea);
    String? trendLabel;
    IconData? trendIcon;
    Color? trendColor;
    if (recent != null) {
      final delta = recent - skill.accuracyPercent;
      if (delta >= 5) {
        trendLabel = 'Improving';
        trendIcon = Icons.trending_up;
        trendColor = Colors.green.shade700;
      } else if (delta <= -5) {
        trendLabel = 'Slipping';
        trendIcon = Icons.trending_down;
        trendColor = scheme.error;
      } else {
        trendLabel = 'Steady';
        trendIcon = Icons.trending_flat;
        trendColor = scheme.outline;
      }
    }

    final ratio = (skill.accuracyPercent / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  skill.skillArea,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${skill.accuracyPercent.toStringAsFixed(0)}%',
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
                  : (ratio >= 0.4 ? scheme.primary : scheme.error),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${skill.correct}/${skill.total} attempts',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (trendLabel != null) ...[
                const Spacer(),
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  trendLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: trendColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  const _DiffChip({required this.stat});

  final DifficultyStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        '${QuestionDifficulty.label(stat.difficulty)} '
        '${stat.accuracyPercent.toStringAsFixed(0)}% '
        '(${stat.correct}/${stat.total})',
      ),
      labelStyle: theme.textTheme.labelMedium,
      visualDensity: VisualDensity.compact,
    );
  }
}
