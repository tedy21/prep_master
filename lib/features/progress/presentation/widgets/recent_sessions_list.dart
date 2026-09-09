import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/exam_section.dart';
import '../../../quiz/domain/entities/quiz_session_record.dart';

class RecentSessionsList extends StatelessWidget {
  const RecentSessionsList({super.key, required this.sessions});

  final List<QuizSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFmt = DateFormat.MMMd().add_jm();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your latest practice and mock sessions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No sessions yet. Finish a practice quiz to see history here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            ...sessions.take(10).map((s) {
              final sectionLabel = s.section?.label;
              final subtitle = [
                if (sectionLabel != null) sectionLabel,
                dateFmt.format(s.completedAt),
              ].join(' · ');
              final good = s.percent >= 70;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: good
                      ? Colors.green.withValues(alpha: 0.15)
                      : scheme.errorContainer.withValues(alpha: 0.5),
                  child: Icon(
                    good ? Icons.trending_up : Icons.trending_flat,
                    color: good ? Colors.green.shade700 : scheme.error,
                    size: 20,
                  ),
                ),
                title: Text(s.title),
                subtitle: Text(subtitle),
                trailing: Text(
                  '${s.percent.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
