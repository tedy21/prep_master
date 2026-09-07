import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/exam_section.dart';

/// 2-column grid of section / skill cards. Tap a card to start practice.
class ExamSectionPicker extends StatelessWidget {
  const ExamSectionPicker({
    super.key,
    required this.examType,
    required this.onSelected,
  });

  final ExamType examType;
  final ValueChanged<ExamSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final sections = ExamSection.forExam(examType);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          examType == ExamType.sat ? 'Sections' : 'Skills',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a card to start practicing',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _SkillCard(
              section: section,
              accentIndex: index,
              onTap: () => onSelected(section),
            );
          },
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.section,
    required this.accentIndex,
    required this.onTap,
  });

  final ExamSection section;
  final int accentIndex;
  final VoidCallback onTap;

  static const _accents = [
    Color(0xFF0D7377),
    Color(0xFF14919B),
    Color(0xFF2A9D8F),
    Color(0xFFE9A825),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accents[accentIndex % _accents.length];
    final surface = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.white;

    return Material(
      color: surface,
      elevation: isDark ? 0 : 1,
      shadowColor: accent.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.2),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.22 : 0.08),
                surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.28 : 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(section.icon, color: accent, size: 24),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: accent.withValues(alpha: 0.85),
                      size: 28,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  section.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  section.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: Icons.timer_outlined,
                      label: '${section.estimatedMinutes} min',
                      color: accent,
                    ),
                    _MetaChip(
                      icon: Icons.quiz_outlined,
                      label: '${section.defaultQuestionCount} Qs',
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
