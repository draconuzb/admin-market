import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../providers.dart';
import '../auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+998');
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _company = TextEditingController();
  final _otp = TextEditingController();
  String _role = 'shop';
  bool _loading = false;
  bool _otpStep = false;

  @override
  void dispose() {
    for (final c in [_phone, _password, _fullName, _company, _otp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final (_, devOtp) = await ref.read(authRepositoryProvider).register(
            phone: _phone.text.trim(),
            password: _password.text,
            role: _role,
            fullName: _fullName.text.trim(),
            companyName: _company.text.trim(),
            language: context.locale.languageCode,
          );
      setState(() {
        _otpStep = true;
        if (devOtp != null) _otp.text = devOtp; // dev convenience
      });
      _snack('auth.otp_sent'.tr());
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(_phone.text.trim(), _otp.text.trim());
      // Log in immediately; the account is pending so the router lands on /pending.
      await ref.read(authControllerProvider.notifier).login(_phone.text.trim(), _password.text);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth.register'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _otpStep ? _buildOtp() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(labelText: 'auth.role'.tr()),
            items: [
              DropdownMenuItem(value: 'shop', child: Text('auth.role_shop'.tr())),
              DropdownMenuItem(value: 'distributor', child: Text('auth.role_distributor'.tr())),
              DropdownMenuItem(value: 'factory', child: Text('auth.role_factory'.tr())),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'shop'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: 'auth.phone'.tr(), hintText: 'auth.phone_hint'.tr()),
            validator: (v) => (v == null || !RegExp(r'^\+998\d{9}$').hasMatch(v.trim()))
                ? 'auth.invalid_phone'.tr()
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fullName,
            decoration: InputDecoration(labelText: 'auth.full_name'.tr()),
            validator: (v) => (v == null || v.trim().isEmpty) ? '—' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _company,
            decoration: InputDecoration(labelText: 'auth.company_name'.tr()),
            validator: (v) => (v == null || v.trim().isEmpty) ? '—' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: 'auth.password'.tr()),
            validator: (v) => (v == null || v.length < 6) ? 'auth.password_short'.tr() : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _register,
            child: _loading ? _spinner() : Text('auth.register'.tr()),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('auth.have_account'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('auth.otp_title'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'auth.otp_title'.tr(),
            hintText: 'auth.otp_hint'.tr(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: _loading ? _spinner() : Text('auth.otp_verify'.tr()),
        ),
      ],
    );
  }

  Widget _spinner() => const SizedBox(
        height: 22, width: 22,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
}
