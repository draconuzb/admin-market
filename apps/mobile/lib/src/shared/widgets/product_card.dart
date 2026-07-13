import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';

/// iOS-style network image with shimmer loading and elegant placeholder.
class ProductImageBox extends StatelessWidget {
  const ProductImageBox({
    super.key,
    required this.imageUrl,
    this.size,
    this.borderRadius,
    this.productName,
  });
  final String? imageUrl;
  final double? size;
  final BorderRadius? borderRadius;
  final String? productName;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.zero;
    final placeholder = _IOSPlaceholder(productName: productName, borderRadius: br);
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: br,
      child: Image.network(
        AppConfig.mediaUrl(imageUrl!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Shimmer.fromColors(
            baseColor: AppTheme.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            highlightColor: AppTheme.isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
            child: Container(color: AppTheme.fill, width: size, height: size),
          );
        },
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _IOSPlaceholder extends StatelessWidget {
  const _IOSPlaceholder({this.productName, required this.borderRadius});
  final String? productName;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: AppTheme.fill,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, color: AppTheme.textTertiary, size: 32),
            if (productName != null && productName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  productName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// iOS-style product card with subtle shadow and clean typography.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImageBox(
                    imageUrl: product.images.isNotEmpty ? product.images.first : null,
                    productName: product.name(lang),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: 8, left: 8,
                      child: _pill('home.featured'.tr(), AppTheme.warning, Icons.star_rounded),
                    ),
                  if (!product.inStock)
                    Positioned(
                      top: 8, right: 8,
                      child: _pill('product.out_of_stock'.tr(), AppTheme.danger, Icons.close),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(product.price),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'product.min_order'.tr()}: ${product.minOrderQty}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

  Widget _pill(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
