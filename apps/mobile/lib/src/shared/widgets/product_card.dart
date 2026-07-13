import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../models/catalog.dart';

/// Network image with a soft skeleton while loading and a graceful fallback.
class ProductImageBox extends StatelessWidget {
  const ProductImageBox({super.key, required this.imageUrl, this.size});
  final String? imageUrl;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 32),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return Image.network(
      AppConfig.mediaUrl(imageUrl!),
      fit: BoxFit.cover,
      width: size,
      height: size,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: ProductImageBox(
                      imageUrl: product.images.isNotEmpty ? product.images.first : null,
                    ),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: 8, left: 8,
                      child: _tag(Icons.star_rounded, 'home.featured'.tr(),
                          const Color(0xFFEA8600)),
                    ),
                  if (!product.inStock)
                    Positioned(
                      top: 8, right: 8,
                      child: _tag(Icons.block, 'product.out_of_stock'.tr(), Colors.red),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, height: 1.2, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(formatPrice(product.price),
                        style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '${'product.min_order'.tr()}: ${product.minOrderQty}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 3),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
