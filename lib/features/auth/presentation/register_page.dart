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

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
    } catch (error, stack) {
      AppLogger.error('Registration failed', error: error, stackTrace: stack);
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
      title: 'Create your account',
      subtitle: 'Start billing smarter in a few minutes.',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Full name',
              controller: _name,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  Validators.required(v, message: 'Name is required'),
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.lg),
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
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Confirm password',
              controller: _confirm,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.matches(() => _password.text),
              onSubmitted: (_) => _submit(),
              enabled: !_loading,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Create account',
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
          const Text('Already have an account?'),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}