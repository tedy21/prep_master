import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../core/widgets/app_views.dart';
import '../bloc/progress_bloc.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        if (state is ProgressLoading || state is ProgressInitial) {
          return const AppLoadingView(message: 'Loading progress…');
        }
        if (state is ProgressError) {
          return AppErrorView(
            message: state.message,
            onRetry: () =>
                context.read<ProgressBloc>().add(const LoadUserProgress()),
          );
        }
        if (state is ProgressLoaded) {
          final p = state.progress;
          final authState = context.watch<AuthBloc>().state;
          final isGuest =
              authState is AuthAuthenticated && authState.isAnonymous;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Your progress',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (isGuest) ...[
                const SizedBox(height: 12),
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
              ],
              const SizedBox(height: 20),
              _StatTile(label: 'Streak', value: '${p.streakDays} days'),
              _StatTile(label: 'XP', value: '${p.xpPoints}'),
              _StatTile(label: 'Level', value: '${p.level}'),
              _StatTile(
                label: 'Sessions',
                value: '${p.sessionsCompleted}',
              ),
              _StatTile(
                label: 'Accuracy',
                value: '${p.accuracyPercent.toStringAsFixed(1)}%',
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
