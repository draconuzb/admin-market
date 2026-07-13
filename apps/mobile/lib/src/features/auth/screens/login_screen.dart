import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme.dart';
import '../auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+998');
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier)
          .login(_phone.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, top + 20, 20, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/language'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.language,
                            color: AppTheme.accent, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/logo_512.png',
                        width: 80, height: 80),
                  ),
                  const SizedBox(height: 16),
                  Text('app_name'.tr(),
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('auth.login'.tr(),
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.textSecondary)),
                ],
              ),
            ),

            // ── Form ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Phone
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'auth.phone'.tr(),
                          hintText: 'auth.phone_hint'.tr(),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            (v == null || !RegExp(r'^\+998\d{9}$').hasMatch(v.trim()))
                                ? 'auth.invalid_phone'.tr()
                                : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Password
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'auth.password'.tr(),
                          prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscure ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'auth.password_short'.tr()
                            : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('auth.login'.tr()),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text('auth.no_account'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
