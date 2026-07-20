import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme.dart';
import '../../../models/address.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../addresses_providers.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key, this.pickMode = false});

  /// When true, tapping an address returns it (used from checkout).
  final bool pickMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('address.title'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text('address.add'.tr()),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.location_on_outlined,
              message: 'address.empty'.tr(),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _AddressCard(
              address: list[i],
              onTap: pickMode
                  ? () => Navigator.of(context).pop(list[i])
                  : () => _openForm(context, ref, existing: list[i]),
              onEdit: () => _openForm(context, ref, existing: list[i]),
              onDelete: () => _delete(context, ref, list[i]),
              onSetDefault: () => _setDefault(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Address? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressForm(existing: existing),
    );
    if (saved == true) ref.invalidate(addressesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Address a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('address.delete_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.delete'.tr(), style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(addressesRepositoryProvider).delete(a.id);
      ref.invalidate(addressesProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref, Address a) async {
    try {
      await ref.read(addressesRepositoryProvider).setDefault(a.id);
      ref.invalidate(addressesProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Address address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(address.label,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('address.default'.tr(),
                                style: const TextStyle(fontSize: 11, color: AppTheme.accent)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${address.fullName} · ${address.phone}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(address.oneLine, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppTheme.textTertiary),
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'default':
                      onSetDefault();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text('common.edit'.tr())),
                  if (!address.isDefault)
                    PopupMenuItem(value: 'default', child: Text('address.make_default'.tr())),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('common.delete'.tr(),
                        style: const TextStyle(color: AppTheme.danger)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({this.existing});
  final Address? existing;
  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _region;
  late final TextEditingController _district;
  late final TextEditingController _street;
  late final TextEditingController _landmark;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? '');
    _name = TextEditingController(text: a?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _region = TextEditingController(text: a?.region ?? '');
    _district = TextEditingController(text: a?.district ?? '');
    _street = TextEditingController(text: a?.street ?? '');
    _landmark = TextEditingController(text: a?.landmark ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final c in [_label, _name, _phone, _region, _district, _street, _landmark]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'label': _label.text.trim(),
      'full_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'region': _region.text.trim(),
      'district': _district.text.trim().isEmpty ? null : _district.text.trim(),
      'street': _street.text.trim(),
      'landmark': _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
      'is_default': _isDefault,
    };
    try {
      final repo = ref.read(addressesRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(data);
      } else {
        await repo.update(widget.existing!.id, data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'common.required'.tr() : null;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.separator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.existing == null ? 'address.add'.tr() : 'address.edit'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _field(_label, 'address.label', hint: 'address.label_hint', validator: _required),
              _field(_name, 'address.full_name', validator: _required),
              _field(_phone, 'address.phone', keyboard: TextInputType.phone, validator: _required),
              _field(_region, 'address.region', validator: _required),
              _field(_district, 'address.district'),
              _field(_street, 'address.street', validator: _required, maxLines: 2),
              _field(_landmark, 'address.landmark'),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: Text('address.set_default'.tr(), style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('common.save'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String labelKey, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelKey.tr(),
          hintText: hint?.tr(),
        ),
      ),
    );
  }
}
