import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('cart.title'.tr())),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(cartControllerProvider.notifier).reload(),
        ),
        data: (cart) => cart.isEmpty
            ? EmptyView(message: 'cart.empty'.tr(), icon: Icons.shopping_bag_outlined)
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
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: cart.items.length,
            itemBuilder: (_, i) {
              final line = cart.items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_outlined,
                          color: AppTheme.textTertiary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.nameUz,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(line.factoryName,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              QtyStepper(
                                value: line.quantity,
                                min: line.minOrderQty,
                                max: line.stockQty,
                                onChanged: (v) =>
                                    onChange(() => notifier.updateQty(line.id, v)),
                              ),
                              const Spacer(),
                              Text(formatPrice(line.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Delete
                    GestureDetector(
                      onTap: () => onChange(() => notifier.remove(line.id)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.close, size: 18,
                            color: AppTheme.textTertiary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // ── Bottom summary ──
        Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20,
              MediaQuery.of(context).padding.bottom + 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cart.factoryCount > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppTheme.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'cart.split_notice'.tr(args: ['${cart.factoryCount}']),
                            style: const TextStyle(
                                color: AppTheme.warning, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                onPressed: () => context.push('/checkout'),
                child: Text('cart.checkout'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
