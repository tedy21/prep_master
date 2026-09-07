import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/theme_cubit.dart';
import 'about_page.dart';
import 'appearance_page.dart';
import 'profile_page.dart';

/// Settings hub — each item opens its own screen.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Account',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isGuest =
                    state is! AuthAuthenticated || state.isAnonymous;
                final phone =
                    state is AuthAuthenticated ? state.phoneNumber : null;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      isGuest ? Icons.person_outline : Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(isGuest ? 'Guest' : (phone ?? 'Signed in')),
                  subtitle: Text(
                    isGuest ? 'Sign in to sync progress' : 'Manage your account',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: const ProfilePage(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                return ListTile(
                  leading: Icon(_themeIcon(mode)),
                  title: const Text('Appearance'),
                  subtitle: Text(_themeLabel(mode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AppearancePage(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Support',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About PrepMaster'),
                  subtitle: const Text('Version and app info'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }

  static String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };
  }
}
