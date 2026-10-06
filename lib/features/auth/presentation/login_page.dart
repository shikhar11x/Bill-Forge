import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/auth/presentation/widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // On success the router redirect replaces this page.
      await ref
          .read(authControllerProvider.notifier)
          .signIn(email: _email.text, password: _password.text);
    } catch (error, stack) {
      AppLogger.error('Sign-in failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        const UnexpectedFailure().message,
        type: ToastType.error,
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Sign in',
      subtitle: 'Enter your details to continue.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Email',
              hint: 'you@yourshop.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.mail_outline_rounded,
              validator: Validators.email,
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Password',
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
              onSubmitted: (_) => _submit(),
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Sign in',
              expanded: true,
              isLoading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('New to BillForge?'),
          TextButton(
            onPressed: () => context.go(AppRoutes.register),
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }
}
