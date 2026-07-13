import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/install_banner.dart';
import '../../../shared/widgets/product_card.dart';
import '../catalog_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _catIcons = [
    Icons.restaurant_rounded, Icons.local_cafe_rounded, Icons.kitchen_rounded,
    Icons.category_rounded, Icons.shopping_basket_rounded,
  ];
  static const _catColors = [
    Color(0xFFFF6B35), Color(0xFF5856D6), Color(0xFF34C759),
    Color(0xFFFF9500), Color(0xFFFF2D55),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final categories = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredProductsProvider);
    final factories = ref.watch(factoriesProvider);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(factoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Hero header ──
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('app_name'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                'home.subtitle'.tr(args: ['']),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search bar
                    GestureDetector(
                      onTap: () => context.push('/products'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 10),
                            Text('catalog.search_hint'.tr(),
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── PWA install banner (web only, when available) ──
            const SliverToBoxAdapter(child: InstallBanner()),

            // ── Categories ──
            SliverToBoxAdapter(child: _section('home.categories'.tr())),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: categories.maybeWhen(
                  data: (list) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final color = _catColors[i % _catColors.length];
                      return GestureDetector(
                        onTap: () => context.push('/products?category=${list[i].id}'),
                        child: SizedBox(
                          width: 76,
                          child: Column(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(_catIcons[i % _catIcons.length],
                                    color: color, size: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                list[i].name(lang),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  orElse: () => const SizedBox(),
                ),
              ),
            ),

            // ── Featured ──
            SliverToBoxAdapter(child: _section('home.featured'.tr())),
            featured.when(
              loading: () => const SliverToBoxAdapter(
                  child: SizedBox(height: 280, child: GridSkeleton(count: 4))),
              error: (e, _) => SliverToBoxAdapter(
                  child: SizedBox(height: 120, child: ErrorView(message: e.toString()))),
              data: (list) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ProductCard(
                        product: list[i],
                        onTap: () => context.push('/product/${list[i].id}')),
                    childCount: list.length,
                  ),
                ),
              ),
            ),

            // ── Factories ──
            SliverToBoxAdapter(child: _section('home.factories'.tr())),
            factories.when(
              loading: () => const SliverToBoxAdapter(
                  child: SizedBox(height: 80, child: LoadingView())),
              error: (e, _) => const SliverToBoxAdapter(child: SizedBox()),
              data: (list) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final f = list[i];
                    return GestureDetector(
                      onTap: () => context.push('/products?factory=${f.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            _factoryAvatar(f),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 16)),
                                  if (f.region != null) ...[
                                    const SizedBox(height: 2),
                                    Text(f.region!,
                                        style: const TextStyle(
                                            fontSize: 13, color: AppTheme.textSecondary)),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _factoryAvatar(dynamic f) {
    if (f.logoUrl != null && f.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          AppConfig.mediaUrl(f.logoUrl!),
          width: 48, height: 48, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _textAvatar(f.name),
        ),
      );
    }
    return _textAvatar(f.name);
  }

  Widget _textAvatar(String name) => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          name.characters.first.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      );

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      );
}
