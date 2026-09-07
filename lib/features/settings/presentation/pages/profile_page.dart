import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isGuest =
              state is! AuthAuthenticated || state.isAnonymous;
          final phone =
              state is AuthAuthenticated ? state.phoneNumber : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    isGuest ? Icons.person_outline : Icons.person,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isGuest ? 'Guest' : (phone ?? 'Signed in'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isGuest
                    ? 'You are browsing as a guest. Sign in to keep streak, XP, and history across devices.'
                    : 'Your progress syncs to the cloud with this account.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Account type'),
                      trailing: Text(
                        isGuest ? 'Guest' : 'Phone account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      trailing: Text(
                        isGuest ? '—' : (phone ?? '—'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        isGuest
                            ? Icons.cloud_off_outlined
                            : Icons.cloud_done_outlined,
                      ),
                      title: const Text('Cloud sync'),
                      trailing: Text(
                        isGuest ? 'Off' : 'On',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isGuest)
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: const LoginPage(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will continue as a guest on this device. '
          'Sign in again anytime to sync progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOut());
    }
  }
}
