import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/theme_cubit.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Theme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how PrepMaster looks on this device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ThemeOption(
                      title: 'System default',
                      subtitle: 'Match your phone light or dark mode',
                      icon: Icons.brightness_auto_outlined,
                      selected: mode == ThemeMode.system,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.system),
                    ),
                    const Divider(height: 1),
                    _ThemeOption(
                      title: 'Light',
                      subtitle: 'Bright background, teal accents',
                      icon: Icons.light_mode_outlined,
                      selected: mode == ThemeMode.light,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.light),
                    ),
                    const Divider(height: 1),
                    _ThemeOption(
                      title: 'Dark',
                      subtitle: 'Easier on the eyes at night',
                      icon: Icons.dark_mode_outlined,
                      selected: mode == ThemeMode.dark,
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : const Icon(Icons.circle_outlined, size: 22),
      onTap: onTap,
    );
  }
}
