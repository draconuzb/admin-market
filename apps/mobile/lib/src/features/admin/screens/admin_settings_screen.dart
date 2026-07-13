import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../admin_providers.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _commission = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _commission.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateSettings({'commission_percent': _commission.text.trim()});
      ref.invalidate(adminSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('common.save'.tr())));
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
    final async = ref.watch(adminSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('admin.settings_title'.tr())),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminSettingsProvider),
        ),
        data: (settings) {
          if (!_loaded) {
            _commission.text = settings['commission_percent'] ?? '';
            _loaded = true;
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _commission,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'admin.commission_percent'.tr()),
                ),
                const SizedBox(height: 20),
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
        },
      ),
    );
  }
}
