import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/question_difficulty.dart';
import '../../../../core/models/exam_section.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_views.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../quiz/domain/entities/quiz_session_args.dart';
import '../../../quiz/domain/services/adaptive_practice_helper.dart';
import '../../../quiz/presentation/pages/quiz_session_page.dart';
import '../../../settings/presentation/cubit/adaptive_practice_cubit.dart';
import '../../domain/services/fallback_coach.dart';
import '../../domain/usecases/get_progress_dashboard.dart';
import '../bloc/progress_bloc.dart';
import '../widgets/accuracy_trend_chart.dart';
import '../widgets/ai_coach_card.dart';
import '../widgets/recent_sessions_list.dart';
import '../widgets/skill_breakdown.dart';
import '../widgets/streak_hero.dart';
import '../widgets/topic_analytics_card.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, this.onStartPractice});

  final VoidCallback? onStartPractice;

  Future<void> _launchAdaptiveForWeakSkill(
    BuildContext context,
    String? skillArea,
  ) async {
    final mapped = AdaptivePracticeHelper.sectionForSkill(skillArea);
    final adaptive = context.read<AdaptivePracticeCubit>().state;
    var seed = QuestionDifficulty.medium;
    if (adaptive) {
      final dash = await sl<GetProgressDashboard>()(const NoParams());
      dash.fold((_) {}, (dashboard) {
        seed = AdaptivePracticeHelper.seedDifficulty(
          dashboard: dashboard,
          section: mapped.section,
        );
      });
    }

    if (!context.mounted) return;
    await QuizSessionPage.open(
      context,
      QuizSessionArgs(
        title: mapped.section.practiceTitle(mapped.examType),
        examType: mapped.examType,
        section: mapped.section,
        questionCount: mapped.section.defaultQuestionCount,
        adaptive: adaptive,
        initialDifficulty: seed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        if (state is ProgressLoading || state is ProgressInitial) {
          return const _ProgressSkeleton();
        }
        if (state is ProgressError) {
          return AppErrorView(
            message: state.message,
            onRetry: () =>
                context.read<ProgressBloc>().add(const LoadUserProgress()),
          );
        }
        if (state is ProgressLoaded) {
          final dashboard = state.dashboard;
          final insight =
              dashboard.aiInsight ?? FallbackCoach.build(dashboard);
          final authState = context.watch<AuthBloc>().state;
          final isGuest =
              authState is AuthAuthenticated && authState.isAnonymous;
          final weak = dashboard.weakestSkill?.skillArea;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProgressBloc>().add(const LoadUserProgress());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (isGuest) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: const Text('Sign in to sync progress'),
                      subtitle: const Text(
                        'Guest mode saves on this device only.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AuthBloc>(),
                            child: const LoginPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                StreakHero(dashboard: dashboard),
                const SizedBox(height: 12),
                AiCoachCard(
                  insight: insight,
                  refreshing: state.aiRefreshing,
                  onRefresh: () => context.read<ProgressBloc>().add(
                        const RefreshProgressAiCoach(force: true),
                      ),
                  onPracticeWeakArea: () =>
                      _launchAdaptiveForWeakSkill(context, weak),
                  weakAreaLabel: weak,
                ),
                const SizedBox(height: 12),
                AccuracyTrendChart(percents: dashboard.accuracyTrend),
                const SizedBox(height: 12),
                TopicAnalyticsCard(dashboard: dashboard),
                const SizedBox(height: 12),
                SkillBreakdown(skills: dashboard.skillStats),
                const SizedBox(height: 12),
                RecentSessionsList(sessions: dashboard.recentSessions),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
