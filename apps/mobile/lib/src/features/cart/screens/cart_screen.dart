import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../models/cart.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/qty_stepper.dart';
import '../cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _change(WidgetRef ref, BuildContext context, Future<void> Function() op) async {
    try {
      await op();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cartControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text('cart.title'.tr())),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(cartControllerProvider.notifier).reload(),
        ),
        data: (cart) => cart.isEmpty
            ? EmptyView(message: 'cart.empty'.tr(), icon: Icons.shopping_cart_outlined)
            : _CartBody(cart: cart, onChange: (op) => _change(ref, context, op)),
      ),
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart, required this.onChange});
  final Cart cart;
  final Future<void> Function(Future<void> Function()) onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartControllerProvider.notifier);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (_, i) {
              final line = cart.items[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.nameUz, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(line.factoryName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QtyStepper(
                        value: line.quantity,
                        min: line.minOrderQty,
                        max: line.stockQty,
                        onChanged: (v) => onChange(() => notifier.updateQty(line.id, v)),
                      ),
                      const Spacer(),
                      Text(formatPrice(line.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onChange(() => notifier.remove(line.id)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        _Summary(cart: cart),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cart.factoryCount > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'cart.split_notice'.tr(args: ['${cart.factoryCount}']),
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                ),
              ),
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
              onPressed: () => context.push('/checkout'),
              child: Text('cart.checkout'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
