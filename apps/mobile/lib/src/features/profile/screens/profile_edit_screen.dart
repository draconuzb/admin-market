import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_views.dart';
import '../../auth/auth_controller.dart';
import '../profile_providers.dart';

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text('profile.edit'.tr())),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (p) => _Form(
          fullName: p.fullName,
          companyName: p.company?.name ?? '',
          region: p.company?.region ?? '',
          address: p.company?.address ?? '',
          inn: p.company?.inn ?? '',
          hasCompany: p.company != null,
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({
    required this.fullName,
    required this.companyName,
    required this.region,
    required this.address,
    required this.inn,
    required this.hasCompany,
  });
  final String fullName, companyName, region, address, inn;
  final bool hasCompany;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.fullName);
  late final _company = TextEditingController(text: widget.companyName);
  late final _region = TextEditingController(text: widget.region);
  late final _address = TextEditingController(text: widget.address);
  late final _inn = TextEditingController(text: widget.inn);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _company, _region, _address, _inn]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).update({
        'full_name': _name.text.trim(),
        if (widget.hasCompany) 'company_name': _company.text.trim(),
        if (widget.hasCompany) 'company_region': _region.text.trim(),
        if (widget.hasCompany) 'company_address': _address.text.trim(),
        if (widget.hasCompany) 'company_inn': _inn.text.trim(),
      });
      ref.invalidate(profileProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('common.save'.tr())));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_name, 'auth.full_name'.tr(), required: true),
          if (widget.hasCompany) ...[
            _field(_company, 'auth.company_name'.tr(), required: true),
            _field(_region, 'profile.region'.tr()),
            _field(_address, 'profile.address'.tr()),
            _field(_inn, 'profile.inn'.tr()),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '—' : null
              : null,
        ),
      );
}
