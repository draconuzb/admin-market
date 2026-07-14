import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../auth/auth_controller.dart';
import '../../reviews/reviews_repository.dart';
import '../catalog_providers.dart';

class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productReviewsProvider(productId));
    final isBuyer = ref.watch(authControllerProvider).user?.isBuyer ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('reviews.title'.tr(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (isBuyer)
              TextButton.icon(
                onPressed: () => _writeReview(context, ref),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text('reviews.write'.tr()),
              ),
          ],
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox(),
          data: (page) => page.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('reviews.empty'.tr(),
                      style: const TextStyle(color: AppTheme.textSecondary)),
                )
              : Column(
                  children: [
                    for (final r in page.items)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.fill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.userName,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                StarRating(rating: r.rating, size: 14),
                              ],
                            ),
                            if (r.comment != null && r.comment!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.comment!,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 14)),
                            ],
                            const SizedBox(height: 4),
                            Text(DateFormat('dd.MM.yyyy').format(r.createdAt),
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textTertiary)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _writeReview(BuildContext context, WidgetRef ref) {
    var rating = 5;
    final comment = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (sheetCtx, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('reviews.write'.tr(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  StarInput(value: rating, onChanged: (v) => setSheet(() => rating = v)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: comment,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: 'reviews.comment_hint'.tr()),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(reviewsRepositoryProvider)
                            .submit(productId, rating, comment.text.trim());
                        ref.invalidate(productReviewsProvider(productId));
                        ref.invalidate(productDetailProvider(productId));
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      } on ApiException catch (e) {
                        if (sheetCtx.mounted) {
                          ScaffoldMessenger.of(sheetCtx)
                              .showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    child: Text('common.save'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
