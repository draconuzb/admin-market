import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../models/address.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../../addresses/addresses_providers.dart';
import '../../addresses/screens/addresses_screen.dart';
import '../../orders/orders_providers.dart';
import '../cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _comment = TextEditingController();
  bool _placing = false;
  Address? _selectedAddress;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      await ref.read(ordersRepositoryProvider).checkout(
            comment: _comment.text.trim(),
            addressId: _selectedAddress?.id,
          );
      await ref.read(cartControllerProvider.notifier).clearLocal();
      ref.invalidate(ordersListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('cart.order_placed'.tr())));
        context.go('/orders');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  /// The explicitly-picked address, else the saved default, else none.
  Address? _resolveAddress() {
    if (_selectedAddress != null) return _selectedAddress;
    final list = ref.watch(addressesProvider).valueOrNull;
    if (list == null || list.isEmpty) return null;
    return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cartControllerProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('cart.checkout'.tr())),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (cart) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (cart.factoryCount > 1) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppTheme.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'cart.split_notice'.tr(args: ['${cart.factoryCount}']),
                              style: const TextStyle(
                                  color: AppTheme.warning, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Delivery address
                  _AddressPicker(
                    selected: _resolveAddress(),
                    onPick: (a) => setState(() => _selectedAddress = a),
                  ),
                  const SizedBox(height: 16),

                  // Items
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < cart.items.length; i++) ...[
                          if (i > 0)
                            const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Divider(height: 0.5, thickness: 0.5),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cart.items[i].nameUz,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${cart.items[i].quantity} × ${formatPrice(cart.items[i].unitPrice)}',
                                        style: const TextStyle(
                                            fontSize: 13, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(formatPrice(cart.items[i].subtotal),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 15)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: TextField(
                      controller: _comment,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'orders.title'.tr(),
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom bar
            Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20,
                  MediaQuery.of(context).padding.bottom + 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                    top: BorderSide(color: AppTheme.separator, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('cart.total'.tr(),
                          style: const TextStyle(
                              fontSize: 15, color: AppTheme.textSecondary)),
                      Text(formatPrice(cart.total),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (_placing || cart.isEmpty) ? null : _placeOrder,
                    child: _placing
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('cart.checkout'.tr()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressPicker extends StatelessWidget {
  const _AddressPicker({required this.selected, required this.onPick});
  final Address? selected;
  final void Function(Address) onPick;

  Future<void> _pick(BuildContext context) async {
    final picked = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => const AddressesScreen(pickMode: true)),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final a = selected;
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(a == null ? Icons.add_location_alt_outlined : Icons.location_on,
                  color: AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: a == null
                    ? Text('address.select'.tr(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${a.label} · ${a.fullName}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(a.oneLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
