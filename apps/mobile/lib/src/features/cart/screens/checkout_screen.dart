import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
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

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      await ref.read(ordersRepositoryProvider).checkout(comment: _comment.text.trim());
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cartControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text('cart.checkout'.tr())),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (cart) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (cart.factoryCount > 1)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('cart.split_notice'.tr(args: ['${cart.factoryCount}'])),
                      ),
                    ),
                  const SizedBox(height: 8),
                  for (final line in cart.items)
                    ListTile(
                      dense: true,
                      title: Text(line.nameUz),
                      subtitle: Text('${line.quantity} × ${formatPrice(line.unitPrice)}'),
                      trailing: Text(formatPrice(line.subtotal)),
                    ),
                  const Divider(),
                  TextField(
                    controller: _comment,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'orders.title'.tr(),
                      hintText: '...',
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('cart.total'.tr(), style: const TextStyle(fontSize: 16)),
                        Text(formatPrice(cart.total),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: (_placing || cart.isEmpty) ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text('cart.checkout'.tr()),
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
