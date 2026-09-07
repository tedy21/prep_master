import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_views.dart';
import '../../../../injection.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../bloc/auth_bloc.dart';

/// Boots auth (anonymous by default) then shows the main app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthStarted()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: AppLoadingView(message: 'Starting PrepMaster…'),
            );
          }
          if (state is AuthError) {
            return Scaffold(
              body: AppErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<AuthBloc>().add(const AuthStarted()),
              ),
            );
          }
          if (state is AuthAuthenticated || state is AuthUnauthenticated) {
            return const HomePage();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
