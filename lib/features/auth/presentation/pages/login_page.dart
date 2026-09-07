import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/phone_auth_mapper.dart';
import '../../../../core/widgets/app_views.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final bloc = context.read<AuthBloc>();
    if (_isRegister) {
      bloc.add(AuthRegisterWithPhone(phone: phone, password: password));
    } else {
      bloc.add(AuthSignInWithPhone(phone: phone, password: password));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Create account' : 'Sign in')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && !state.isAnonymous) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const AppLoadingView(message: 'Signing in…');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Save progress across devices',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your phone number and password. '
                    'Guest mode still works on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '09XX XXX XXXX',
                      prefixText: '+251 ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your phone number';
                      }
                      return PhoneAuthMapper.validate(v.trim());
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (state is AuthError) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(_isRegister ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Sign in with Google (coming soon)'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
